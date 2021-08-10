resource "aws_sns_topic" "pagerduty" {
  name = "alarms-for-pagerduty"
}

resource "aws_sns_topic_subscription" "pagerduty_subscription" {
  topic_arn = aws_sns_topic.pagerduty.arn
  protocol  = "https"
  endpoint  = var.sns_topic_subscription_https_endpoint
}