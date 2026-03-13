resource "aws_cloudwatch_metric_alarm" "authentication_api_no_healthy_hosts" {
  alarm_name          = "${var.env_name} ${var.aws_region_name} authentication API no healthy hosts"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "HealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Average"
  threshold           = "1"
  datapoints_to_alarm = "1"

  dimensions = {
    LoadBalancer = aws_lb.authentication_api.arn_suffix
  }

  alarm_description = "Load balancer detects no healthy authentication API targets. Investigate api cluster and CloudWatch logs for root cause."

  alarm_actions = compact([
    var.pagerduty_notifications_arn,
    var.critical_notifications_arn
  ])
}

resource "aws_cloudwatch_metric_alarm" "authentication_api_node_unhealthy" {
  alarm_name          = "${var.env_name}-authentication-api-alb node unhealthy"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Minimum"
  threshold           = "0.0"
  alarm_description   = "Failure of any ALB Node in \"authentication api-alb-wifi\" consistently for a 5 minute period\n\nCheck the end points of the ALB to see if there is an issue"

  alarm_actions = [var.capacity_notifications_arn]

  dimensions = {
    TargetGroup  = aws_alb_target_group.private_auth_api_tg.arn_suffix
    LoadBalancer = aws_lb.authentication_api.arn_suffix
  }
}

resource "aws_cloudwatch_metric_alarm" "user_signup_api_no_healthy_hosts" {
  count = var.user_signup_enabled

  alarm_name          = "${var.env_name} user signup API no healthy hosts"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "HealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Average"
  threshold           = "1"
  datapoints_to_alarm = "1"

  dimensions = {
    LoadBalancer = aws_lb.user_signup_api[0].arn_suffix
  }

  alarm_description = "Load balancer detects no healthy user signup API targets. Investigate api ECS cluster and CloudWatch logs for root cause."

  alarm_actions = compact([
    var.pagerduty_notifications_arn,
    var.critical_notifications_arn
  ])
}

resource "aws_cloudwatch_metric_alarm" "user_signup_api_node_unhealthy" {
  count = var.user_signup_enabled

  alarm_name          = "${var.env_name}-user-signup-api-wifi Node Unhealthy"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Minimum"
  threshold           = "0.0"
  alarm_description   = "Failure of any ALB Node in \"user-signup-api-wifi\" consistently for a 5 minute period\n\nCheck the end points of the ALB to see if there is an issue\nCheck the end points to see if there is an issue"

  alarm_actions = [
    var.devops_notifications_arn,
    var.capacity_notifications_arn
  ]

  dimensions = {
    TargetGroup  = aws_alb_target_group.user_signup_api_tg[0].arn_suffix
    LoadBalancer = aws_lb.user_signup_api[0].arn_suffix
  }
}

resource "aws_cloudwatch_metric_alarm" "user_signup_api_cpu_usage_high" {
  count = var.user_signup_enabled

  alarm_name          = "${var.env_name}-user-signup-CPU-usage-high-(snowflake)"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "3"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "5.0"
  alarm_description   = "user signup CPU high"

  alarm_actions = [
    var.capacity_notifications_arn,
    var.devops_notifications_arn,
  ]

  dimensions = {
    ClusterName = aws_ecs_cluster.api_cluster.name
    ServiceName = aws_ecs_service.user_signup_api_service[0].name
  }
}
