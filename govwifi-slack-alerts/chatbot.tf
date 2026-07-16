## TechDebt, Refactor, can now use the native aws provider for slack chatbot, but leaving the awscc provider in for now as its used in production and would require a migration plan to move to the native provider.
resource "awscc_chatbot_slack_channel_configuration" "aws_slack_chatbot" {
  for_each = var.create_slack_alerts > 0 ? local.chatbot_configs : {}

  configuration_name = each.value.configuration_name
  iam_role_arn       = aws_iam_role.govwifi_london_aws_chatbot_role[0].arn
  slack_workspace_id = local.slack_workplace_id
  slack_channel_id   = each.value.slack_channel_id
  sns_topic_arns     = each.value.sns_topic_arns
  # Add this line to force Chatbot to emit error logs
  logging_level = "ERROR"
}