resource "aws_cloudwatch_metric_alarm" "unhealthy_hosts_warning" {
  alarm_name          = "${var.env_name} ${var.aws_region_name} frontend-unhealthy hosts"
  alarm_description   = "Warning: Detected unhealthy Radius Frontend hosts on the LB, check status, logs, monitor and reboot tasks if required."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/NetworkELB"
  period              = 60
  statistic           = "Maximum"
  threshold           = var.radius_instance_count/2
  datapoints_to_alarm = 1

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
    TargetGroup  = aws_lb_target_group.main.arn_suffix
  }

  alarm_actions = [
    var.capacity_notifications_arn
  ]
}

resource "aws_cloudwatch_metric_alarm" "no_healthy_hosts" {
  alarm_name          = "${var.env_name} ${var.aws_region_name} frontend no healthy hosts"
  alarm_description   = "Alert: Detected when there are no healthy radius frontend targets, investigate and reboot tasks"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 5
  metric_name         = "HealthyHostCount"
  namespace           = "AWS/NetworkELB"
  period              = 60
  statistic           = "Minimum"
  threshold           = 1
  datapoints_to_alarm = 1

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
    TargetGroup  = aws_lb_target_group.main.arn_suffix
  }

  alarm_actions = [
    var.critical_notifications_arn,
    var.pagerduty_notifications_arn
  ]
}

resource "aws_cloudwatch_metric_alarm" "radius_cannot_connect_to_api" {
  alarm_name          = "${var.env_name}-${var.aws_region_name}-radius-cannot-connect-to-api"
  alarm_description   = "FreeRADIUS cannot connect to the Logging and/or Authentication API. Investigate CloudWatch logs for root cause."
  comparison_operator = "GreaterThanThreshold"
  threshold           = 10
  evaluation_periods  = 5
  datapoints_to_alarm = 3
  period              = 60
  statistic           = "Sum"
  treat_missing_data  = "missing"
  metric_name         = aws_cloudwatch_log_metric_filter.radius_cannot_connect_to_api.metric_transformation[0].name
  namespace           = aws_cloudwatch_log_metric_filter.radius_cannot_connect_to_api.metric_transformation[0].namespace

  alarm_actions = [
    var.critical_notifications_arn
  ]
}

resource "aws_cloudwatch_metric_alarm" "eap_outer_and_inner_identities_are_the_same" {
  alarm_name          = "${var.env_name}-${var.aws_region_name}-EAP Outer and inner identities are the same"
  alarm_description   = "WLC using the real identity for the anonymous identity - Radius Misconfiguration"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = aws_cloudwatch_log_metric_filter.outer_and_inner_identities_same.name
  namespace           = "LogMetrics"
  period              = "86400"
  statistic           = "Maximum"
  threshold           = 1.0

  alarm_actions = [var.critical_notifications_arn]
}

## Radius has a limit of 4096 sessions, if a task is overloaded, this message will appear in the logs, indicating a task or loadbalancer failure.
resource "aws_cloudwatch_metric_alarm" "eap_too_many_sessions" {
  alarm_name          = "${var.env_name}-${var.aws_region_name}-EAP_too_many_open_sessions"
  alarm_description  = "Radius has a limit of 4096 sessions, if task overloaded, this message will appear in logs, indicating task/loadbalancer failure, investigate, restart tasks"
  comparison_operator = "GreaterThanThreshold"
  namespace           = "LogMetrics"
  metric_name         = aws_cloudwatch_log_metric_filter.eap_too_many_session.name
  threshold           = 10
  evaluation_periods  = 5
  datapoints_to_alarm = 3
  period              = 60
  statistic           = "Sum"
  treat_missing_data  = "missing"
  alarm_actions = [var.critical_notifications_arn]
}
