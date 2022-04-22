locals{
  #aws_api_gateway_method  
  method_list = flatten([
    for k in keys(var.api_gw_resources_and_methods) : [
      for method in var.api_gw_resources_and_methods[k]["methods"] : {
        key   = k
        method = method
        request_templates = request_templates
        request_parameters = request_parameters
        passthrough_behavior = passthrough_behavior
        uri = uri

      }
    ]
  ])

  validation_domains = var.api_gw_custom_domain_enabled ? [for k, v in aws_acm_certificate.apigw_certificate[0].domain_validation_options : tomap(v)] : []

  #resources and methods
  #total_methods = {for k,v in var.api_gw_resources_and_methods : for each method in var.api_gw_resources_and_methods[k]["methods"] : join(",",[k,method])={"resource"=k,"method"=method}}

}

resource "aws_api_gateway_rest_api" "apigw" {
  name = var.api_gw_name
  minimum_compression_size = var.minimum_compression_size
  api_key_source = var.api_key_source
  body = var.api_gw_body
  parameters = var.api_gw_parameters
  
  endpoint_configuration {
    types = ["EDGE", "PRIVATE"]
    vpc_endpoint_ids = module.endpoints.endpoints.api_gw.id
  }
}

resource "aws_api_gateway_resource" "api_gw_resource_for_each" {
  for_each = var.api_gw_resources_and_methods
  rest_api_id = aws_api_gateway_rest_api.apigw.id
  parent_id = aws_api_gateway_rest_api.apigw.root_resource_id
  path_part = each.value["path"]
}

resource "aws_api_gateway_authorizer" "api_gw_authorizer" {
  name = "api_gw_authorizer"
  type = var.aws_api_gateway_authorizer_type # (TOKEN, REQUEST, COGNITO_USER_POOLS)
  rest_api_id = aws_api_gateway_rest_api.apigw.id

  provider_arns = aws_cognito_user_pool.api_gw_pool.arn # arn:aws:cognito-idp:{region}:{account_id}:userpool/{user_pool_id}
}

resource "aws_api_gateway_method" "api_gw_method_for_each" {
  depends_on = [aws_api_gateway_authorizer.api_gw_authorizer]
  count = length(local.method_list)

  rest_api_id = aws_api_gateway_rest_api.apigw.id
  resource_id = aws_api_gateway_resource.api_gw_resource_for_each[local.method_list[count.index].key].id
  http_method = local.method_list[count.index].method

  authorization = var.api_gw_method_authorization # (NONE, CUSTOM, AWS_IAM, COGNITO_USER_POOLS)
  authorizer_id = aws_api_gateway_authorizer.api_gw_authorizer.id
  authorization_scopes = local.authorization_scopes

  request_models = var.api_gw_models
  request_parameters = var.api_gw_request_parameters
}

resource "aws_api_gateway_request_validator" "api_gw_validator" {
  name                        = "api_gw_validator"
  rest_api_id                 = aws_api_gateway_rest_api.apigw.id
  validate_request_body       = true
  validate_request_parameters = true
}

resource "aws_api_gateway_integration" "api_gw_for_each" {
  count = length(local.method_list)
  rest_api_id = aws_api_gateway_rest_api.apigw.id
  resource_id = aws_api_gateway_method.api_gw_method_for_each[count.index].resource_id
  http_method = aws_api_gateway_method.api_gw_method_for_each[count.index].http_method #(GET, POST, PUT, DELETE, HEAD, OPTION, ANY)

  integration_http_method = aws_api_gateway_method.api_gw_method_for_each[count.index].http_method #(GET, POST, PUT, DELETE, HEAD, OPTION, ANY)
  type = HTTP
  uri = local.method_list[count.index].uri
  passthrough_behavior = local.method_list[count.index].passthrough_behavior
  request_templates = local.method_list[count.index].request_templates
  request_parameters = local.method_list[count.index].request_parameters

  connection_type = "VPC_LINK"
  connection_id = aws_api_gateway_vpc_link.api_gw_vpc_link.id
}

resource "aws_api_gateway_vpc_link" "api_gw_vpc_link" {
  name        = "api_gw_vpc_link"
  target_arns = [module.vpc.vgw_arn]
}

resource "aws_api_gateway_deployment" "api_gw_deployment" {
  depends_on  = [aws_api_gateway_integration.api_gw_for_each]
  rest_api_id = aws_api_gateway_rest_api.apigw.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_method.api_gw_method_for_each.resource_id,
      aws_api_gateway_integration.api_gw_for_each.id,
    ]))
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_account" "api_gw_account" {
  cloudwatch_role_arn = aws_iam_role.api_gw_cloudwatch.arn
}

resource "aws_api_gateway_stage" "api_gw_stage" {
  depends_on = [aws_cloudwatch_log_group.api_gw_group]
  deployment_id = aws_api_gateway_deployment.apigw_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.apigw.id
  stage_name    = var.api_gw_stage_name
}

resource "aws_api_gateway_method_settings" "apigw_method_settings" {
  rest_api_id = aws_api_gateway_rest_api.apigw.id
  stage_name  = aws_api_gateway_stage.api_gw_stage.stage_name
  method_path = "*/*"
  settings {
    metrics_enabled        = true
    data_trace_enabled     = true
    logging_level          = "INFO"
    # Limit the rate of calls to prevent abuse and unwanted charges
    throttling_rate_limit  = var.api_gw_rate_limit
    throttling_burst_limit = var.api_gw_burst_limit
  }
}

resource "aws_api_gateway_client_certificate" "api_gw_client_certificate" {
  description = "api_gw_client_certificate"
}


resource "aws_api_gateway_rest_api_policy" "api_gw_policy" {
  rest_api_id = aws_api_gateway_rest_api.apigw.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": "*",
        "Action": "execute-api:Invoke",
        "Resource": [
          "execute-api:/*"
        ]
      },
      {
        "Effect": "Deny",
        "Principal": "*",
        "Action": "execute-api:Invoke",
        "Resource": [
          "execute-api:/*"
        ],
        "Condition" : {
          "StringNotEquals": {
            "aws:SourceVpce": "${aws_vpc_endpoint.vpc_endpoint.id}"
          }
        }
      }
    ]
  }
EOF
}
