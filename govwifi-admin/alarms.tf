resource "aws_cloudwatch_metric_alarm" "admin-no-healthy-hosts" {
  alarm_name          = "${var.Env-Name} admin no healthy hosts"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "HealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Average"
  threshold           = "1"
  datapoints_to_alarm = "1"

  dimensions = {
    LoadBalancer = aws_lb.admin-alb.arn_suffix
  }

  alarm_description = "Load balancer detects no healthy admin targets. Investigate admin-api ECS cluster and CloudWatch logs for root cause."

  alarm_actions = compact([
    var.notification_arn,
  ])
}
