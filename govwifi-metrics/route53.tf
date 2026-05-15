resource "aws_route53_record" "metrics" {
  zone_id = var.route53_zone_id
  name    = "metrics.${var.env_subdomain}.service.gov.uk"
  type    = "A"

  alias {
    name                   = aws_lb.metrics_alb.dns_name
    zone_id                = aws_lb.metrics_alb.zone_id
    evaluate_target_health = true
  }
}
