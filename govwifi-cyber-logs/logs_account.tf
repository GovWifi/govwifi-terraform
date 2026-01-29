// For these data sources please provide 2 AWS providers with Main and Logs accounts, or declare variables with Account IDs
provider "aws" {
  region = var.region
}

output "destination_arn" {
  description = "Source account Cloudwatch Logs Destination ARN"
  value       = aws_cloudwatch_log_destination.kinesis_log_destination.arn
}
