resource "aws_cloudwatch_metric_alarm" "athena_cost_alarm" {
  count               = var.region == "eu-west-2" ? 1 : 0
  alarm_name          = "High-Athena-Data-Scanned-Daily"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "ProcessedBytes"
  namespace           = "AWS/Athena"
  period              = "86400" # 1 Day (24 hours)
  statistic           = "Sum"
  threshold           = "107374182400" # 100 GB ($0.50 per day threshold)
  alarm_description   = "Alerts if Athena scans > 10Gb of data in 24 hours, usually caused by select * type queries, which can incur high costs, please refine your queries."

  # Ensure you filter specifically for your Workgroup
  dimensions = {
    WorkGroup = aws_athena_workgroup.govwifi_logs_workgroup[0].name
  }

  # Link this to your existing SNS topic for alerts
  alarm_actions = [var.capacity_notifications_arn]
}