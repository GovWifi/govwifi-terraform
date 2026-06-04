resource "aws_iam_role" "govwifi_wifi_london_aws_chatbot_role" {
  count       = var.create_slack_alert
  name        = "govwifi-aws-chatbot-role"
  path        = "/"
  description = "Role to enable Amazon Chatbot to function."

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "chatbot.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}