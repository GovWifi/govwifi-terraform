resource "aws_cloudwatch_event_rule" "daily_session_deletion_event" {
  count               = var.event_rule_count
  name                = "${var.env_name}-daily-session-deletion"
  description         = "Triggers daily 22:00 UTC"
  schedule_expression = "cron(0 22 * * ? *)"
  state               = "ENABLED"
}

resource "aws_cloudwatch_event_rule" "daily_user_deletion_event" {
  count               = var.event_rule_count
  name                = "${var.env_name}-daily-user-deletion"
  description         = "Triggers daily 23:00 UTC"
  schedule_expression = "cron(0 10 * * ? *)"
  state               = "ENABLED"
}

resource "aws_cloudwatch_event_rule" "daily_smoke_test_cleanup_event" {
  count               = var.event_rule_count
  name                = "${var.env_name}-smoke-test-cleanup"
  description         = "Triggers daily 23:30 UTC"
  schedule_expression = "cron(30 23 * * ? *)"
  state               = "ENABLED"
}

resource "aws_cloudwatch_event_rule" "trim_sessions_database_table_event" {
  count               = var.event_rule_count
  name                = "${var.env_name}-trim-sessions-database-table"
  description         = "Triggers daily 00:00 UTC"
  schedule_expression = "cron(0 0 * * ? *)"
  state               = "ENABLED"
}

resource "aws_cloudwatch_event_rule" "daily_gdpr_set_user_last_login" {
  count               = var.event_rule_count
  name                = "${var.env_name}-daily-gdpr-set-user-last-login"
  description         = "Triggers daily 02:00 UTC"
  schedule_expression = "cron(0 2 * * ? *)"
  state               = "ENABLED"
}

resource "aws_cloudwatch_event_rule" "hourly_request_statistics_event" {
  count               = var.event_rule_count
  name                = "${var.env_name}-hourly_request_statistics"
  description         = "Triggers hourly"
  schedule_expression = "cron(0 * * * ? *)"
  state               = "ENABLED"
}

# new daily, weekly and monthly metrics published to S3
resource "aws_cloudwatch_event_rule" "daily_metrics_logging_event" {
  count               = var.event_rule_count
  name                = "${var.env_name}-daily-metrics-logging"
  description         = "Triggers daily 05:00 UTC"
  schedule_expression = "cron(0 5 * * ? *)"
  state               = "ENABLED"
}

resource "aws_cloudwatch_event_rule" "weekly_metrics_logging_event" {
  count               = var.event_rule_count
  name                = "${var.env_name}-weekly-metrics-logging"
  description         = "Triggers every SUN 05:45 UTC"
  schedule_expression = "cron(45 5 ? * 1 *)"
  state               = "ENABLED"
}

resource "aws_cloudwatch_event_rule" "monthly_metrics_logging_event" {
  count               = var.event_rule_count
  name                = "${var.env_name}-monthly-metrics-logging"
  description         = "Triggers on the first of each month at 06:00 UTC"
  schedule_expression = "cron(0 6 1 * ? *)"
  state               = "ENABLED"
}

resource "aws_cloudwatch_event_rule" "retrieve_notifications_event" {
  count               = var.event_rule_count
  name                = "${var.env_name}-retrieve-notifications"
  description         = "Triggers daily 06:00 UTC"
  schedule_expression = "cron(0 6 * * ? *)"
  state               = "ENABLED"
}

resource "aws_cloudwatch_event_rule" "backup_notify_templates_event" {
  count               = var.event_rule_count
  name                = "${var.env_name}-backup-notify-templates"
  description         = "Triggers daily 06:00 UTC"
  schedule_expression = "cron(0 6 * * ? *)"
  state               = "ENABLED"
}

resource "aws_cloudwatch_event_rule" "active_users_signup_survey_event" {
  count               = var.event_rule_count
  name                = "${var.env_name}-active-users-signup-survey"
  description         = "Triggers daily at 1:00PM UTC"
  schedule_expression = "cron(0 13 * * ? *)"
  state               = "ENABLED"
}

resource "aws_cloudwatch_event_rule" "inactive_user_followup_event" {
  count               = var.event_rule_count
  name                = "${var.env_name}-inactive-user-followup"
  description         = "Triggers daily at 6:00PM UTC"
  schedule_expression = "cron(0 18 * * ? *)"
  state               = "ENABLED"
}


resource "aws_cloudwatch_event_rule" "sync_s3_to_elasticsearch_event" {
  count               = var.event_rule_count
  name                = "${var.env_name}-sync-s3-to-elasticsearch"
  description         = "One off task - update scheduled UTC time to rerun"
  schedule_expression = "cron(40 15 29 4 ? 2021)"
  state               = "ENABLED"
}
