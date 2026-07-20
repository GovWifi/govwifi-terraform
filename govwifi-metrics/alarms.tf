# Alarm when the Tableau publication CodeBuild job fails.
resource "aws_cloudwatch_metric_alarm" "tableau_publication_failed" {
  alarm_name          = "${var.env_name}-tableau-publication-failed"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "FailedBuilds"
  namespace           = "AWS/CodeBuild"
  # 86400s == 1day
  period              = "86400"
  statistic           = "Sum"
  threshold           = "1"
  datapoints_to_alarm = "1"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ProjectName = aws_codebuild_project.tableau_data_source_publication.name
  }

  alarm_description = "The Tableau data source publication CodeBuild job failed. Check CloudWatch Logs group 'govwifi-metrics-data-publisher-group' for details. See runbook: https://docs.wifi.service.gov.uk/infrastructure/monitoring"

  alarm_actions = [var.capacity_notifications_arn]
  ok_actions    = [var.capacity_notifications_arn]
}

# Count successful metric records written to the Metrics API.
resource "aws_cloudwatch_log_metric_filter" "metrics_api_records_written" {
  name           = "${var.env}-metrics-api-records-written"
  log_group_name = aws_cloudwatch_log_group.metrics_log_group.name
  pattern        = "{ $.msg = \"Metric recorded\" }"

  metric_transformation {
    name          = "MetricRecordsWritten"
    namespace     = "GovWifi/MetricsAPI"
    value         = "1"
    default_value = "0"
  }
}

# Alarm when no records are written in a 24-hour window.
# default_value = "0" above ensures the metric has data even on silent periods,
# so treat_missing_data = notBreaching is safe here.
resource "aws_cloudwatch_metric_alarm" "metrics_api_no_records_written" {
  alarm_name          = "${var.env_name}-metrics-api-no-records-written"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "MetricRecordsWritten"
  namespace           = "GovWifi/MetricsAPI"
  period              = "86400"
  statistic           = "Sum"
  threshold           = "1"
  datapoints_to_alarm = "1"
  treat_missing_data  = "notBreaching"

  alarm_description = "No metrics have been written to the Metrics API in the past 24 hours. The daily logging task (${var.env_name}-daily-metrics-logging EventBridge rule) may have failed. Check the logging-api CloudWatch Logs and ECS task history."

  alarm_actions = [var.capacity_notifications_arn]
  ok_actions    = [var.capacity_notifications_arn]
}
