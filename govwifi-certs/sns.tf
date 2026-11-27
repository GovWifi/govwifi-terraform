data "aws_secretsmanager_secret_version" "cert_notification_email" {
  secret_id = "cert_rotate/acme_email"
}

resource "aws_sns_topic" "cert_notifications" {
  name = "govwifi-renew-certs-notifications"
}

resource "aws_sns_topic_subscription" "cert_notification_email" {
  topic_arn = aws_sns_topic.cert_notifications.arn
  protocol  = "email"
  endpoint  = data.aws_secretsmanager_secret_version.cert_notification_email.secret_string
}

output "cert_notification_topic_arn" {
  value = aws_sns_topic.cert_notifications.arn
}