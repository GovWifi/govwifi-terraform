resource "aws_cloudwatch_event_rule" "smoke_tests" {
  count       = var.enable_slack_alert
  name        = "smoke-tests-notification"
  description = "Capture any failed smoke-tests and notify smoke-tests sns topic"

  event_pattern = <<EOF
{
  "source": ["aws.codebuild"],
  "detail-type": ["CodeBuild Build Phase Change"],
  "detail": {
    "completed-phase-status": ["FAILED", "TIMED_OUT", "FAULT"],
    "project-name": ["govwifi-smoke-tests"]
  }
}
EOF
}

resource "aws_cloudwatch_event_target" "smoketest-sns" {
  count     = var.enable_slack_alert
  rule      = aws_cloudwatch_event_rule.smoke_tests[0].name
  target_id = "SendSmoketestsToSNS"
  arn       = aws_sns_topic.smoke_tests[0].arn

  input_transformer {
    input_paths = {
      failed_phase  = "$.detail.completed-phase"
      phase_status  = "$.detail.completed-phase-status"
      phase_context = "$.detail.completed-phase-context"
      build_status  = "$.detail.build-status"
      build_id      = "$.detail.build-id"
      initiator     = "$.detail.additional-information.initiator"
      project_name  = "$.detail.project-name"
      log_deep_link = "$.detail.additional-information.logs.deep-link"
    }
    # HERE BE DRAGONS, edit with caution, formatted explicitly to satisfy AWS Chatbot's custom JSON contract, also jasonencode() is not used here because it would escape the JSON and break the formatting, which prevents the input_path from being parsed correctly.
    input_template = "{\"version\":\"1.0\",\"source\":\"custom\",\"content\":{\"textType\":\"client-markdown\",\"title\":\"GovWifi Smoke Test Status\",\"description\":\"The <project_name> job on *${title(var.env)}* triggered by <initiator> has *<phase_status>* at *<failed_phase>* \\n Reason: <phase_context> \\nBuild ID: <build_id> \\nLogs: <log_deep_link>\"}}"
  }
}

## uncomment the below to capture the raw eventbridge json for debugging purposes, this is useful for debugging the event above.

# resource "aws_cloudwatch_log_group" "eventbridge_raw_capture" {
#   count             = var.enable_slack_alert
#   name              = "/aws/events/raw-codebuild-smoke-tests"
#   retention_in_days = 7
# }

# resource "aws_cloudwatch_event_target" "raw_log" {
#   count     = var.enable_slack_alert
#   rule      = aws_cloudwatch_event_rule.smoke_tests[0].name
#   target_id = "CaptureRawEventJson"
#   arn       = aws_cloudwatch_log_group.eventbridge_raw_capture[0].arn
# }

# data "aws_iam_policy_document" "eventbridge_to_cloudwatch" {
#   count = var.enable_slack_alert

#   statement {
#     effect = "Allow"

#     actions = [
#       "logs:CreateLogStream",
#       "logs:PutLogEvents"
#     ]

#     resources = [
#       "${aws_cloudwatch_log_group.eventbridge_raw_capture[0].arn}:*"
#     ]

#     principals {
#       type        = "Service"
#       identifiers = ["events.amazonaws.com"]
#     }
#   }
# }

# # 2. Apply the resource policy to your CloudWatch Logs system
# resource "aws_cloudwatch_log_resource_policy" "eventbridge_logging" {
#   count           = var.enable_slack_alert
#   policy_name     = "allow-eventbridge-to-write-smoke-tests-logs"
#   policy_document = data.aws_iam_policy_document.eventbridge_to_cloudwatch[0].json
# }