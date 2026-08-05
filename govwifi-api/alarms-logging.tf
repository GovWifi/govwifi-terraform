resource "aws_cloudwatch_metric_alarm" "logging_ecs_cpu_alarm_high" {
  count               = var.alarm_count
  alarm_name          = "${var.env_name}-logging-ecs-cpu-alarm-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = "50"

  dimensions = {
    ClusterName = aws_ecs_cluster.api_cluster.name
    ServiceName = aws_ecs_service.logging_api_service[0].name
  }

  alarm_description = "ECS cluster CPU is high, scaling up number of tasks. Investigate api cluster and CloudWatch logs for root cause."

  alarm_actions = [
    aws_appautoscaling_policy.ecs_policy_up_logging[0].arn,
  ]

  treat_missing_data = "breaching"
}

resource "aws_cloudwatch_metric_alarm" "logging_ecs_cpu_alarm_low" {
  count               = var.alarm_count
  alarm_name          = "${var.env_name}-downscale-logging-ecs-cpu-low-alarm"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = var.low_cpu_threshold
  datapoints_to_alarm = "2"

  dimensions = {
    ClusterName = aws_ecs_cluster.api_cluster.name
    ServiceName = aws_ecs_service.logging_api_service[0].name
  }

  alarm_description = "ECS cluster CPU is low, scaling down number of tasks to save on cost."

  alarm_actions = [
    aws_appautoscaling_policy.ecs_policy_down_logging[0].arn,
  ]
}

