resource "aws_api_gateway_domain_name" "api_gw_domain" {
  domain_name   = aws_acm_certificate.api_gw_certificate.domain_name
  certificate_arn = aws_acm_certificate.api_gw_certificate.arn
}

resource "aws_api_gateway_base_path_mapping" "api_gw_base_path" {
  api_id    = aws_api_gateway_rest_api.apigw.id
  domain_name   = aws_api_gateway_domain_name.api_gw_domain.domain_name
  stage_name    = aws_api_gateway_stage.api_gw_stage.stage_name
}

resource "tls_private_key" "api_gw_tls" {
  algorithm = "RSA"
}

resource "tls_self_signed_cert" "api_gw_tls_cert" {
  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
  dns_names             = [var.rest_api_domain_name]
  key_algorithm         = tls_private_key.api_gw_tls.algorithm
  private_key_pem       = tls_private_key.api_gw_tls.private_key_pem
  validity_period_hours = 12

  subject {
    common_name  = var.rest_api_domain_name
    organization = "ORG"
  }
}

resource "aws_acm_certificate" "api_gw_certificate" {
  certificate_body = tls_self_signed_cert.api_gw_tls_cert.cert_pem
  private_key      = tls_private_key.api_gw_tls.private_key_pem
}

resource "aws_route53_record" "api_gw_record" {
  name    = aws_api_gateway_domain_name.api_gw_domain.domain_name
  type    = "A"
  zone_id = aws_route53_zone.api_gw_zone.id

  alias {
    evaluate_target_health = true
    name = aws_api_gateway_domain_name.api_gw_domain.cloudfront_domain_name
    zone_id = aws_api_gateway_domain_name.api_gw_domain.cloudfront_zone_id
  }
}

resource "aws_route53_zone" "api_gw_zone" {
  name = var.rest_api_domain_name
}