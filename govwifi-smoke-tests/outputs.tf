output "topic_arn" {
  value = var.create_slack_alert > 0 ? aws_sns_topic.smoke_tests[0].arn : ""
}