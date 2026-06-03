resource "awscc_chatbot_slack_channel_configuration" "aws_slack_chatbot" {
  for_each = local.chatbot_configs

  configuration_name = each.value.configuration_name
  iam_role_arn       = aws_iam_role.govwifi_wifi_london_aws_chatbot_role[0].arn
  slack_workspace_id = local.slack_workplace_id
  slack_channel_id   = each.value.slack_channel_id
  sns_topic_arns     = each.value.sns_topic_arns
}