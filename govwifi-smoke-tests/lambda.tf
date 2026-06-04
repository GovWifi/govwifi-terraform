# resource "aws_lambda_function" "slack_alert" {
#   count         = var.create_slack_alert
#   filename      = "../../govwifi-smoke-tests/lambda_function.zip"
#   function_name = "slack_alert_terraformed"
#   role          = aws_iam_role.iam_for_lambda[0].arn
#   handler       = "index.handler"
#   description   = "Alerts slack govwifi-monitoring channel on smoke test failure via SNS"

#   runtime       = "nodejs20.x"
#   architectures = ["x86_64"]

#   environment {
#     variables = {
#       URL = data.aws_secretsmanager_secret_version.slack_alert_url[0].secret_string
#     }
#   }

#   depends_on = [
#     data.archive_file.lambda_my_function
#   ]

# }

# resource "aws_iam_role" "slack_alert" {
#   count = var.create_slack_alert
#   name  = "slack_alert"

#   assume_role_policy = <<EOF
# {
#     "Version": "2012-10-17",
#     "Statement": [
#         {
#             "Effect": "Allow",
#             "Principal": {
#                 "Service": "lambda.amazonaws.com"
#             },
#             "Action": "sts:AssumeRole"
#         }
#     ]
# }
# EOF
# }




# data "archive_file" "lambda_my_function" {
#   type             = "zip"
#   source_file      = "../../govwifi-smoke-tests/index.js"
#   output_file_mode = "0666"
#   output_path      = "../../govwifi-smoke-tests/lambda_function.zip"
# }

# resource "aws_lambda_permission" "slack_alert_with_sns" {
#   count         = var.create_slack_alert
#   statement_id  = "AllowExecutionFromSNS"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.slack_alert[0].function_name
#   principal     = "sns.amazonaws.com"
#   source_arn    = aws_sns_topic.smoke_tests[0].arn
# }
