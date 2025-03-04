resource "aws_lambda_function" "user_api_sns_lambda" {
  count         = var.user_signup_enabled
  filename      = "../../govwifi-api/user_api_sns_lambda.zip"
  function_name = "user-api-sns-lambda"
  role          = aws_iam_role.iam_for_user_api_sns_lambda[0].arn
  handler       = "lambda_function.lambda_handler"
  description   = "This lambda forwards traffic from SNS to the user-signup-api"

  source_code_hash = filebase64sha256("../../govwifi-api/user_api_sns_lambda.zip")
  # The unzipped source code can be found at: https://github.com/GovWifi/govwifi-lambda-for-user-signup-api
  # Documentation can found in the README of this directory

  runtime       = "python3.8"
  architectures = ["x86_64"]

  vpc_config {
    subnet_ids         = concat(var.private_subnet_ids)
    security_group_ids = [aws_security_group.lambda_user_api_out[0].id]
  }

  environment {
    variables = {
      ENV = var.env_name
    }
  }
}

resource "aws_lambda_permission" "with_sns" {
  count         = var.user_signup_enabled
  statement_id  = "GovwifiAllowInvokeFromSnsIreland"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.user_api_sns_lambda[0].function_name
  principal     = "sns.amazonaws.com"
  source_arn    = "arn:aws:sns:eu-west-1:${var.aws_account_id}:${var.env_name}-user-signup-notifications"
}
