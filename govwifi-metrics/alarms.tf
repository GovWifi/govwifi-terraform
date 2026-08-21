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

# The six account-health rake tasks in govwifi-admin (see metrics:publish_*
# in govwifi-admin/scheduled-tasks.tf) each post one metric a day under this
# prefix via the same POST /v1/record path the performance metrics use.
locals {
  account_health_metric_names = [
    "account-health-organisation-count",
    "account-health-orgs-with-less-than-two-admins-count",
    "account-health-orgs-with-dormant-admins-count",
    "account-health-orgs-have-no-active-admins-count",
    "account-health-orgs-with-no-signed-mou-count",
    "account-health-orgs-with-no-physical-address-for-ip-count",
  ]
}

# Breaks MetricRecordsWritten above down by metric name, scoped to the
# account-health-* metrics, so a single silently-failing rake task doesn't
# hide behind the other metrics still arriving that day.
resource "aws_cloudwatch_log_metric_filter" "account_health_metrics_written" {
  name           = "${var.env}-account-health-metrics-written"
  log_group_name = aws_cloudwatch_log_group.metrics_log_group.name
  pattern        = "{ $.msg = \"Metric recorded\" && $.name = \"account-health-*\" }"

  metric_transformation {
    name      = "AccountHealthMetricRecordsWritten"
    namespace = "GovWifi/MetricsAPI"
    value     = "1"

    dimensions = {
      MetricName = "$.name"
    }
  }
}

# Alarm per account-health metric when it hasn't been recorded in 24 hours.
# No default_value on the filter above (dimensioned metrics can't have one),
# so a task that didn't run produces no data point at all -- treated as
# breaching, which is exactly the "it didn't happen" signal we want here.
resource "aws_cloudwatch_metric_alarm" "account_health_metric_missing" {
  for_each = toset(local.account_health_metric_names)

  alarm_name          = "${var.env_name}-account-health-metric-missing-${each.value}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "AccountHealthMetricRecordsWritten"
  namespace           = "GovWifi/MetricsAPI"
  period              = "86400"
  statistic           = "Sum"
  threshold           = "1"
  datapoints_to_alarm = "1"
  treat_missing_data  = "breaching"

  dimensions = {
    MetricName = each.value
  }

  alarm_description = "The account health metric '${each.value}' has not been recorded in the Metrics API in the past 24 hours. Check the corresponding 'rake metrics:publish_*' task on the admin ECS cluster. See runbook: https://docs.wifi.service.gov.uk/infrastructure/monitoring#account-health-metrics"

  alarm_actions = [var.capacity_notifications_arn]
  ok_actions    = [var.capacity_notifications_arn]
}

# Alarm when the daily recover_and_publish run logs that the Tableau PAT is
# nearing (or past) expiry. Non-fatal on the Python side by design -- see
# metpub/token_health.py in govwifi-metrics-data-publisher -- so this is the
# only place the warning surfaces to an engineer.
resource "aws_cloudwatch_log_metric_filter" "tableau_pat_expiry_warning" {
  # NB: govwifi-metrics-data-publisher-group is auto-created by the CodeBuild
  # project's logs_config in codebuild.tf, not managed as a Terraform
  # resource here, so the name is a literal match rather than a reference.
  name           = "${var.env}-tableau-pat-expiry-warning"
  log_group_name = "govwifi-metrics-data-publisher-group"
  pattern        = "\"WARNING: Tableau PAT expiry\""

  metric_transformation {
    name          = "TableauPatExpiryWarning"
    namespace     = "GovWifi/MetricsAPI"
    value         = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_metric_alarm" "tableau_pat_expiry_warning" {
  alarm_name          = "${var.env_name}-tableau-pat-expiry-warning"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "TableauPatExpiryWarning"
  namespace           = "GovWifi/MetricsAPI"
  period              = "86400"
  statistic           = "Sum"
  threshold           = "1"
  datapoints_to_alarm = "1"
  treat_missing_data  = "notBreaching"

  alarm_description = "The Tableau Personal Access Token is within 30 days of expiring (or has expired). Rotate it in the govwifi/metrics-data-publisher/tableau secret. See runbook: https://docs.wifi.service.gov.uk/infrastructure/monitoring#rotating-the-tableau-personal-access-token"

  alarm_actions = [var.capacity_notifications_arn]
  ok_actions    = [var.capacity_notifications_arn]
}
