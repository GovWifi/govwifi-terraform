resource "aws_kinesis_firehose_delivery_stream" "cloudwatch_to_s3" {
  name        = "CloudWatch-Logs-to-S3-Archive"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn        = aws_iam_role.logs_to_firehose_role.arn
    bucket_arn      = aws_s3_bucket.log_archive_bucket.arn

    # Corrected buffering parameters:
    buffering_size      = 5  # 5 MiB (Range: 1 to 128 MiB)
    buffering_interval  = 300 # 300 seconds (5 minutes) (Range: 60 to 900 seconds)

    prefix          = "logs/app-name=!{partitionKeyFromQuery:logGroupName}/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/"
    error_output_prefix = "errors/!{firehose:error-output-type}/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/"

    # Enable GZIP compression for cost savings
    compression_format = "GZIP"

    # Dynamic Partitioning is required for the logGroupName prefix
    processing_configuration {
      enabled = true
      processors {
        type = "CloudWatchLogProcessing"
      }
      processors {
        type = "AppendDelimiterToRecord"
        parameters {
          parameter_name  = "Delimiter"
          parameter_value = "\\n" # Append newline to each log for easy parsing
        }
      }
    }

    # Enable logging for Firehose delivery errors
    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = "${var.env_name}-firehose-to-S3-Archive"
    }
  }
}