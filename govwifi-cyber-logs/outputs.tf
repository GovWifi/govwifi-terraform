data "aws_caller_identity" "current" {}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "destination_arn" {
  description = "Source account Cloudwatch Logs Destination ARN"
  value       = aws_cloudwatch_log_destination.kinesis_log_destination.arn
}