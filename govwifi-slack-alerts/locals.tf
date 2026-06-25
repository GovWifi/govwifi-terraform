locals {
  slack_workplace_id           = jsondecode(data.aws_secretsmanager_secret_version.slack_credentials.secret_string)["workspace-id"]
  slack_monitor_channel_id     = jsondecode(data.aws_secretsmanager_secret_version.slack_credentials.secret_string)["channel-id"]
  slack_alerts_channel_id      = jsondecode(data.aws_secretsmanager_secret_version.slack_credentials.secret_string)["alerts-channel-id"]
  slack_smoke_tests_channel_id = jsondecode(data.aws_secretsmanager_secret_version.slack_credentials.secret_string)["smoke-tests-channel-id"]
}

locals {
  chatbot_configs = var.create_slack_alert > 0 ? {
    "alert" = {
      configuration_name = "govwifi-chatbot-alert-configuration"
      slack_channel_id   = local.slack_alerts_channel_id
      sns_topic_arns = [
        var.london_critical_notifications_topic_arn,
        var.dublin_critical_notifications_topic_arn,
        var.route53_critical_notifications_topic_arn
      ]
    }
    "monitor" = {
      configuration_name = "govwifi-slack-chatbot-monitoring-configuration"
      slack_channel_id   = local.slack_monitor_channel_id
      sns_topic_arns = [
        var.london_capacity_notifications_topic_arn,
        var.dublin_capacity_notifications_topic_arn
      ]
    }
    "smoke_tests" = {
      configuration_name = "govwifi-chatbot-smoke-tests-configuration"
      slack_channel_id   = local.slack_smoke_tests_channel_id
      sns_topic_arns = [
        var.smoketest_notifications_topic_arn
      ]
    }
  } : {}
}