resource "aws_cognito_user_pool" "api_gw_pool" {
  depends_on = [aws_api_gateway_rest_api.apigw]
  name                       = "api_gw_pool"
  alias_attributes        = ["preferred_username"]

  admin_create_user_config {
    allow_admin_create_user_only = false
  }
  password_policy {
    minimum_length    = 8
    require_uppercase = true
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
  }
  tags = var.tags
}

resource "aws_cognito_user_pool_client" "client" {
  depends_on = [aws_api_gateway_rest_api.apigw]
  name = var.cognito_user_pool_client_name
  allowed_oauth_flows_user_pool_client = true
  supported_identity_providers = ["COGNITO"]
  user_pool_id    = aws_cognito_user_pool.api_gw_pool.id
  generate_secret = true
  allowed_oauth_flows = ["client_credentials"]
  allowed_oauth_scopes = aws_cognito_resource_server.aws_gw_cognito_server.scope_identifiers
  callback_urls = [local.callback_url]
  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]
}

resource "aws_cognito_resource_server" "aws_gw_cognito_server" {
  depends_on = [aws_api_gateway_rest_api.apigw]
  identifier = local.callback_url
  name       = "aws_gw_cognito_server"
  user_pool_id = aws_cognito_user_pool.api_gw_pool.id
  
  scope {
    scope_name        = var.cognito_user_pool_scope_name
    scope_description = var.cognito_user_pool_scope_description
  }
}