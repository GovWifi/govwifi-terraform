resource "aws_route53_record" "wifi_apex" {
  zone_id = var.route53_zone_id
  name    = "wifi.service.gov.uk"
  type    = "A"
  ttl     = "300"
  records = ["185.199.108.153", "185.199.109.153", "185.199.110.153", "185.199.111.153"]
}

resource "aws_route53_record" "www_wifi" {
  zone_id = var.route53_zone_id
  name    = "www.wifi.service.gov.uk"
  type    = "CNAME"
  ttl     = "300"
  records = ["govwifi.github.io."]
}

resource "aws_cloudwatch_metric_alarm" "product_pages" {
  alarm_name          = "product-pages-health-check-alarm"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HealthCheckStatus"
  namespace           = "AWS/Route53"
  period              = "60"
  statistic           = "Minimum"
  threshold           = "1"
  alarm_description   = "Alarm for Product Pages Route 53 health check failure"
  actions_enabled     = true
  alarm_actions       = [var.critical_notifications_arn]
  treat_missing_data  = "missing"

  dimensions = {
    HealthCheckId = aws_route53_health_check.product_pages.id
  }
}

resource "aws_route53_health_check" "product_pages" {
  fqdn              = "www.wifi.service.gov.uk"
  port              = 443
  type              = "HTTPS"
  resource_path     = "/"
  failure_threshold = "3"
  request_interval  = "30"

  tags = {
    Name = "Product pages healthcheck"
  }
}

resource "aws_route53_record" "tech_docs" {
  zone_id = var.route53_zone_id
  name    = "docs.wifi.service.gov.uk"
  type    = "CNAME"
  ttl     = "300"
  records = ["govwifi.github.io."]
}

resource "aws_route53_health_check" "tech_docs" {
  fqdn              = "docs.wifi.service.gov.uk"
  port              = 443
  type              = "HTTPS"
  resource_path     = "/"
  failure_threshold = "3"
  request_interval  = "30"

  tags = {
    Name = "Tech docs - offering GovWifi- healthcheck"
  }
}

resource "aws_cloudwatch_metric_alarm" "tech_docs" {
  alarm_name          = "tech-docs-health-check-alarm"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HealthCheckStatus"
  namespace           = "AWS/Route53"
  period              = "60"
  statistic           = "Minimum"
  threshold           = "1"
  alarm_description   = "Alarm for Product Pages Route 53 health check failure"
  actions_enabled     = true
  alarm_actions       = [var.critical_notifications_arn]
  treat_missing_data  = "missing"

  dimensions = {
    HealthCheckId = aws_route53_health_check.tech_docs.id
  }
}

resource "aws_route53_record" "dev_docs" {
  zone_id = var.route53_zone_id
  name    = "dev-docs.wifi.service.gov.uk"
  type    = "CNAME"
  ttl     = "300"
  records = ["govwifi.github.io."]
}

resource "aws_route53_health_check" "dev_docs" {
  fqdn              = "dev-docs.wifi.service.gov.uk"
  port              = 443
  type              = "HTTPS"
  resource_path     = "/"
  failure_threshold = "3"
  request_interval  = "30"

  tags = {
    Name = "Dev docs healthcheck"
  }
}

resource "aws_cloudwatch_metric_alarm" "dev_docs" {
  alarm_name          = "dev-docs-health-check-alarm"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HealthCheckStatus"
  namespace           = "AWS/Route53"
  period              = "60"
  statistic           = "Minimum"
  threshold           = "1"
  alarm_description   = "Alarm for Product Pages Route 53 health check failure"
  actions_enabled     = true
  alarm_actions       = [var.critical_notifications_arn]
  treat_missing_data  = "missing"

  dimensions = {
    HealthCheckId = aws_route53_health_check.dev_docs.id
  }
}
