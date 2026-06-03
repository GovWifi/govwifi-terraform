resource "aws_cloudwatch_event_rule" "smoke_tests" {
  count       = var.create_slack_alert
  name        = "smoke-tests-notification"
  description = "Capture any failed smoke-tests and notify smoke-tests sns topic"

  event_pattern = <<EOF
{
  "source": ["aws.codebuild"],
  "detail-type": ["CodeBuild Build State Change"],
  "detail": {
    "build-status": ["FAILED"],
    "project-name": ["govwifi-smoke-tests"]
  }
}
EOF
}

resource "aws_cloudwatch_event_target" "smoketest-sns" {
  count     = var.create_slack_alert
  rule      = aws_cloudwatch_event_rule.smoke_tests[0].name
  target_id = "SendSmoketestsToSNS"
  arn       = aws_sns_topic.smoke_tests[0].arn
}

## Custom Alert Message

# resource "aws_cloudwatch_event_target" "sns" {
#   count     = var.create_slack_alert
#   rule      = aws_cloudwatch_event_rule.smoke_tests[0].name
#   target_id = "SendSmoketestsToSNS"
#   arn       = aws_sns_topic.smoke_tests[0].arn

#   input_transformer {
#     input_paths = {
#       build_id = "$.detail.build-id"
#     }

#     # Format explicitly to satisfy AWS Chatbot's custom JSON contract
#     input_template = jsonencode({
#       version = "1.0"
#       source  = "custom"
#       content = {
#         textType    = "client-markdown"
#         title       = "⚠️ GovWifi Smoke Test Failure"
#         description = "<!here> *${var.env}* smoke test has failed. Build ID: <build_id>"
#       }
#     })
#   }
#}