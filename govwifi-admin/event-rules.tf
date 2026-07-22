# rake cleanup:orphans

resource "aws_cloudwatch_event_rule" "daily_cleanup_data" {
  name                = "${var.env_name}-daily-cleanup-data"
  description         = "Triggers daily 03:15 UTC"
  schedule_expression = "cron(15 3 * * ? *)"
  state               = "ENABLED"
}

resource "aws_cloudwatch_event_rule" "daily_median_metrics" {
  name                = "${var.env_name}-daily-median-metrics"
  description         = "Triggers daily 05:15 UTC"
  schedule_expression = "cron(15 5 * * ? *)"
  state               = "ENABLED"
}

# rake backup:service_emails

resource "aws_cloudwatch_event_rule" "daily_backup_service_emails" {
  name                = "${var.env_name}-daily-backup-service-emails"
  description         = "Triggers daily 03:30 UTC"
  schedule_expression = "cron(30 3 * * ? *)"
  state               = "ENABLED"
}

# rake export_certificates
resource "aws_cloudwatch_event_rule" "daily_export_certificates" {
  name                = "${var.env_name}-daily-export-certificates"
  description         = "Triggers daily 22:00 UTC"
  schedule_expression = "cron(00 22 * * ? *)"
  state               = "ENABLED"
}

# rake publish_organisation_names
resource "aws_cloudwatch_event_rule" "daily_publish_organisation_names" {
  name                = "${var.env_name}-daily-publish-organisation-names"
  description         = "Triggers daily 22:00 UTC"
  schedule_expression = "cron(00 22 * * ? *)"
  state               = "ENABLED"
}

resource "aws_cloudwatch_event_rule" "daily_smoke_test_reset_event" {
  name                = "${var.env_name}-smoke-test-reset"
  description         = "Triggers daily 23:30 UTC"
  schedule_expression = "cron(30 23 * * ? *)"
  state               = "ENABLED"
}

# rake metrics:publish_organisation_count
resource "aws_cloudwatch_event_rule" "daily_publish_organisation_count" {
  name                = "${var.env_name}-daily-publish-organisation-count"
  description         = "Triggers daily 05:00 UTC"
  schedule_expression = "cron(00 5 * * ? *)"
  state               = "ENABLED"
}

# rake metrics:publish_orgs_with_dormant_admins_count
resource "aws_cloudwatch_event_rule" "daily_publish_orgs_with_dormant_admins_count" {
  name                = "${var.env_name}-daily-publish-orgs-with-dormant-admins-count"
  description         = "Triggers daily 05:15 UTC"
  schedule_expression = "cron(15 5 * * ? *)"
  state               = "ENABLED"
}

# rake metrics:publish_orgs_with_less_than_two_admins_count
resource "aws_cloudwatch_event_rule" "daily_publish_orgs_with_less_than_two_admins_count" {
  name                = "${var.env_name}-daily-publish-orgs-with-less-than-two-admins-count"
  description         = "Triggers daily 05:30 UTC"
  schedule_expression = "cron(30 5 * * ? *)"
  state               = "ENABLED"
}