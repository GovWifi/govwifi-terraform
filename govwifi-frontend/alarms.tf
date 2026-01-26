resource "aws_cloudwatch_metric_alarm" "unhealthy_hosts_warning" {
  alarm_name          = "${var.env_name} ${var.aws_region_name} frontend-unhealthy hosts"
  alarm_description   = "Warning: Detected unhealthy Radius Frontend hosts on the LB, check status, logs, monitor and reboot tasks if required."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/NetworkELB"
  period              = 60
  statistic           = "Maximum"
  threshold           = var.radius_task_count / 2
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
  evaluation_periods  = 2
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
#* I don't believe this works, the name and namespace, don't match the metric */
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

## Radius has a limit of open sessions, if a task is overloaded, this message will appear in the logs, indicating a task or loadbalancer failure.
resource "aws_cloudwatch_metric_alarm" "eap_too_many_sessions_high" {
  alarm_name          = "${var.env_name}-${var.aws_region_name}-EAP-too-many-open-sessions"
  alarm_description   = "Radius has a limit of EAP Open sessions, this should now trigger the auto scaler to spin up new tasks, monitor as this indicates increase in traffic or a radius problem."
  metric_name         = aws_cloudwatch_log_metric_filter.eap_too_many_sessions.metric_transformation[0].name
  threshold           = 1 #error in logs detected
  statistic           = "Maximum"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  datapoints_to_alarm = 1
  evaluation_periods  = 5 # situation experienced for 5 periods (5 x 60 seconds)
  period              = 60
  namespace           = aws_cloudwatch_log_metric_filter.eap_too_many_sessions.metric_transformation[0].namespace
  treat_missing_data  = "notBreaching"
  alarm_actions = [
    aws_appautoscaling_policy.ecs_service_radius_frontend_load_scale_up_policy.arn,
    var.critical_notifications_arn
  ]
}

/* As it's not possible to determine when the error event will be over, the scale down will be a manual codebuild job */

resource "aws_cloudwatch_metric_alarm" "radius_cluster_high_cpu_utilization" {
  alarm_name          = "${var.env_name}-${var.aws_region_name}-radius-high-cpu-80-percent"
  alarm_description   = "Triggers when Radius Service average CPU exceeds 80% for 15 minutes across the cluster, indicating high load. Investigate and consider scaling up."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 3
  datapoints_to_alarm = 3 # Require all 3 periods to be breaching.
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 300 # 5 minutes (300 seconds)
  statistic           = "Average"
  threshold           = 80 # The 80% CPU threshold
  treat_missing_data  = "notBreaching"
  dimensions = {
    ClusterName = aws_ecs_cluster.frontend_fargate.name
    ServiceName = aws_ecs_service.load_balanced_frontend_service.name
  }
  alarm_actions = [var.critical_notifications_arn]
}

resource "aws_cloudwatch_metric_alarm" "radius_cluster_high_memory_utilization" {
  alarm_name          = "${var.env_name}-${var.aws_region_name}-radius-high-memory-80-percent"
  alarm_description   = "Triggers when Radius Service average Memory usage exceeds 80% for 15 minutes across the cluster, indicating high load. Investigate and consider scaling up."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 3
  datapoints_to_alarm = 3 # Require all 3 periods to be breaching.
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 300 # 5 minutes (300 seconds)
  statistic           = "Average"
  threshold           = 80 # The 80% CPU threshold
  treat_missing_data  = "notBreaching"
  dimensions = {
    ClusterName = aws_ecs_cluster.frontend_fargate.name
    ServiceName = aws_ecs_service.load_balanced_frontend_service.name
  }
  alarm_actions = [var.critical_notifications_arn]
}