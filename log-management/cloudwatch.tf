# # CloudWatch Alarms for monitoring
# resource "aws_cloudwatch_metric_alarm" "firehose_delivery_errors" {
#   for_each            = local.log_groups
#   alarm_name          = "${var.env_name}-firehose-delivery-errors"
#   comparison_operator = "GreaterThanThreshold"
#   evaluation_periods  = "2"
#   metric_name         = "DeliveryToS3.Success"
#   namespace           = "AWS/Kinesis/Firehose"
#   period              = "300"
#   statistic           = "Average"
#   threshold           = "0.95"
#   alarm_description   = "This metric monitors firehose delivery success rate"
#   alarm_actions       = [] # Add SNS capacity (notification) topic ARN here for notifications

#   dimensions = {
#     DeliveryStreamName = aws_kinesis_firehose_delivery_stream.cloudwatch_to_s3[each.key].arn
#   }

#   tags = {
#     Name        = "Firehose Delivery Errors"
#   }
# }

# CloudWatch Log Group for Firehose errors
resource "aws_cloudwatch_log_group" "firehose_error_log_group" {
  name              = "${var.env_name}-firehose-to-S3-Archive"
  retention_in_days = var.log_retention

  tags = {
    Name = "Firehose Error Logs"
  }
}

# CloudWatch Log Stream for Firehose errors
resource "aws_cloudwatch_log_stream" "firehose_error_log_stream" {
  name           = "S3Delivery"
  log_group_name = aws_cloudwatch_log_group.firehose_error_log_group.name
}

# CloudWatch Logs subscription filters for each application
resource "aws_cloudwatch_log_subscription_filter" "log_subscription" {
  for_each = local.log_groups

  name            = "${each.key}-firehose-subscription"
  log_group_name  = each.value
  filter_pattern  = "" # Empty pattern means all logs
  destination_arn = aws_kinesis_firehose_delivery_stream.cloudwatch_to_s3[each.key].arn
  role_arn        = aws_iam_role.logs_to_firehose_role.arn

  depends_on = [
    aws_iam_role_policy.cloudwatch_logs_firehose_policy
  ]
}