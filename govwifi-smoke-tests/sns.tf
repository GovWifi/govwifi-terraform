resource "aws_sns_topic" "smoke_tests" {
  count = var.enable_slack_alert
  name  = "govwifi-smoke-tests"
}

