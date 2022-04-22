resource "aws_api_gateway_api_key" "dei" {
  name = "Disaster Everywhere INC dev key"
}

resource "aws_api_gateway_api_key" "wbt" {
  name = "We Broke Things dev key"
}

resource "aws_api_gateway_usage_plan" "api_gw_usage_plan_dei" {
  name         = "api_gw_usage_plan_dei"
  description  = "Disaster Everywhere INC usage plan"

  api_stages {
    api_id = aws_api_gateway_rest_api.api_gw_stage.id
    stage  = aws_api_gateway_stage.api_gw_stage.stage_name
  }


  quota_settings {
    limit  = var.dei_limit
    offset = var.dei_offset
    period = var.dei_period
  }

  throttle_settings {
    burst_limit = var.dei_burst_limit
    rate_limit  = var.dei_rate_limit
  }
}

resource "aws_api_gateway_usage_plan_key" "api_gw_usage_plan_dei_key" {
  key_id        = aws_api_gateway_api_key.dei.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.api_gw_usage_plan_dei.id
}


resource "aws_api_gateway_usage_plan" "api_gw_usage_plan_wbt" {
  name         = "api_gw_usage_plan_wbt"
  description  = "We Broke Things usage plan"

  api_stages {
    api_id = aws_api_gateway_rest_api.api_gw_stage.id
    stage  = aws_api_gateway_stage.api_gw_stage.stage_name
  }


  quota_settings {
    limit  = var.wbt_limit
    offset = var.wbt_offset
    period = var.wbt_period
  }

  throttle_settings {
    burst_limit = var.wbt_burst_limit
    rate_limit  = var.wbt_rate_limit
  }
}

resource "aws_api_gateway_usage_plan_key" "api_gw_usage_plan_wbt_key" {
  key_id        = aws_api_gateway_api_key.wbt.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.api_gw_usage_plan_wbt.id
}