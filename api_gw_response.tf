locals {
  api_gw_response_map = {
    ACCESS_DENIED                  = 403
    API_CONFIGURATION_ERROR        = 500
    AUTHORIZER_CONFIGURATION_ERROR = 500
    AUTHORIZER_FAILURE             = 500
    BAD_REQUEST_PARAMETERS         = 400
    BAD_REQUEST_BODY               = 400
    DEFAULT_4XX                    = 400
    DEFAULT_5XX                    = 500
    EXPIRED_TOKEN                  = 403
    INTEGRATION_FAILURE            = 504
    INTEGRATION_TIMEOUT            = 504
    INVALID_API_KEY                = 403
    INVALID_SIGNATURE              = 403
    MISSING_AUTHENTICATION_TOKEN   = 403
    QUOTA_EXCEEDED                 = 429
    REQUEST_TOO_LARGE              = 413
    RESOURCE_NOT_FOUND             = 404
    THROTTLED                      = 429
    UNAUTHORIZED                   = 401
    UNSUPPORTED_MEDIA_TYPE         = 415
  }

  method_response_list = flatten([
    for k in keys(var.api_gw_resources_and_methods) : [
      for method in var.api_gw_resources_and_methods[k]["methods_response"] : {
        key   = k
        method_response = method_response
        schema = schema
        request_templates = request_templates
        request_parameters = request_parameters
      }
    ]
  ])
}

resource "aws_api_gateway_gateway_response" "api_gw_response" {
  for_each = local.api_gw_response_map

  rest_api_id   = aws_api_gateway_rest_api.apigw.id
  response_type = each.key
  status_code   = each.value

  response_templates = {
    "application/json" = "{\"message\": $context.error.messageString}"
  }

  response_parameters = {
    "gatewayresponse.header.Access-Control-Allow-Origin" = "'*'"
    "gatewayresponse.header.Content-Type"                = "'application/json'"
  }
}

resource "aws_api_gateway_method_response" "api_gw_method_response_for_each" {
  depends_on = [aws_api_gateway_authorizer.api_gw_authorizer]
  count = length(local.method_list)
  rest_api_id = aws_api_gateway_rest_api.apigw.id
  resource_id = aws_api_gateway_resource.api_gw_resource_for_each[local.method_list[count.index].key].id
  http_method = aws_api_gateway_method.api_gw_method_for_each[count.index].http_method
  status_code = "200"
}

resource "aws_api_integration_response" "api_gw_response_for_each" {
  count = length(local.method_response_list)
  rest_api_id = aws_api_gateway_rest_api.apigw.id
  resource_id = aws_api_gateway_method.api_gw_method_for_each[count.index].resource_id
  http_method = aws_api_gateway_method.api_gw_method_for_each[count.index].http_method # (GET, POST, PUT, DELETE, HEAD, OPTION, ANY)
  status_code = aws_api_gateway_method_response.api_gw_method_response_for_each[count.index]

  request_templates = local.method_response_list[count.index].request_templates
  request_parameters = local.method_response_list[count.index].request_parameters

}

resource "aws_api_gateway_model" "api_gw_model" {
  for_each = var.api_gw_resources_and_methods
  rest_api_id  = aws_api_gateway_rest_api.apigw.id
  name         = "api_gw_model"
  content_type = "application/json"
  schema = local.method_response_list[count.index].schema
}