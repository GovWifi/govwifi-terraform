resource "aws_acm_certificate" "metrics_cert" {
  domain_name       = "metrics.${var.env_subdomain}.service.gov.uk"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = var.tags
}

resource "aws_route53_record" "metrics_cert_validation" {
  name    = one(aws_acm_certificate.metrics_cert.domain_validation_options).resource_record_name
  type    = one(aws_acm_certificate.metrics_cert.domain_validation_options).resource_record_type
  zone_id = var.route53_zone_id
  records = [one(aws_acm_certificate.metrics_cert.domain_validation_options).resource_record_value]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "metrics_cert" {
  certificate_arn         = aws_acm_certificate.metrics_cert.arn
  validation_record_fqdns = [aws_route53_record.metrics_cert_validation.fqdn]
}
