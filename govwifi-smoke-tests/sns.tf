resource "aws_sns_topic" "smoke_tests" {
  count = var.create_slack_alert
  name  = "govwifi-smoke-tests"
}

# resource "aws_cloudwatch_event_rule" "smoke_tests" {
#   count       = var.create_slack_alert
#   name        = "smoke-tests-notification"
#   description = "Capture any failed smoke-tests and notify smoke-tests sns topic"

#   event_pattern = <<EOF
# {
#   "source": ["aws.codebuild"],
#   "detail-type": ["CodeBuild Build State Change"],
#   "detail": {
#     "build-status": ["FAILED"],
#     "project-name": ["govwifi-smoke-tests"]
#   }
# }
# EOF

# }



# resource "aws_sns_topic_policy" "smoke_tests" {
#   count = var.create_slack_alert
#   arn   = aws_sns_topic.smoke_tests[0].arn

#   policy = <<EOF
# {
#   "Version": "2008-10-17",
#   "Id": "__default_policy_ID",
#   "Statement": [
#     {
#       "Sid": "__default_statement_ID",
#       "Effect": "Allow",
#       "Principal": {
#         "AWS": "*"
#       },
#       "Action": [
#         "SNS:GetTopicAttributes",
#         "SNS:SetTopicAttributes",
#         "SNS:AddPermission",
#         "SNS:RemovePermission",
#         "SNS:DeleteTopic",
#         "SNS:Subscribe",
#         "SNS:ListSubscriptionsByTopic",
#         "SNS:Publish"
#       ],
#       "Resource": "arn:aws:sns:eu-west-2:${var.aws_account_id}:govwifi-smoke-tests",
#       "Condition": {
#         "StringEquals": {
#           "AWS:SourceOwner": "${var.aws_account_id}"
#         }
#       }
#     },
#     {
#       "Sid": "eventbridgesmoke",
#       "Effect": "Allow",
#       "Principal": {
#         "Service": "events.amazonaws.com"
#       },
#       "Action": "sns:Publish",
#       "Resource": "arn:aws:sns:eu-west-2:${var.aws_account_id}:govwifi-smoke-tests"
#     },
#     {
#       "Sid": "AWSEvents_smoke-tests-notification_SendSmoketestsToSNS",
#       "Effect": "Allow",
#       "Principal": {
#         "Service": "events.amazonaws.com"
#       },
#       "Action": "sns:Publish",
#       "Resource": "arn:aws:sns:eu-west-2:${var.aws_account_id}:govwifi-smoke-tests"
#     }
#   ]
# }
# EOF

# }



# resource "aws_cloudwatch_event_target" "sns" {
#   count     = var.create_slack_alert
#   rule      = aws_cloudwatch_event_rule.smoke_tests[0].name
#   target_id = "SendSmoketestsToSNS"
#   arn       = aws_sns_topic.smoke_tests[0].arn

#   input_transformer {
#     input_paths = {
#       build-id = "$.detail.build-id",
#     }

#     input_template = "\"@here ${var.env} smoke test failure: <build-id>\""
#   }
# }

# resource "aws_sns_topic_subscription" "slack_alert_target" {
#   count     = var.create_slack_alert
#   topic_arn = aws_sns_topic.smoke_tests[0].arn
#   protocol  = "lambda"
#   endpoint  = aws_lambda_function.slack_alert[0].arn
# }
