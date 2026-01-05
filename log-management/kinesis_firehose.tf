resource "aws_kinesis_firehose_delivery_stream" "cloudwatch_to_s3" {
  ## create a stream for each log group defined in locals
  for_each = local.log_groups

  # Unique name for each stream (e.g., firehose-api-gateway, firehose-backend)
  name        = "CloudWatch-Logs-to-S3-Archive-for-${each.key}"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn   = aws_iam_role.firehose_delivery_role.arn
    bucket_arn = aws_s3_bucket.log_archive_bucket.arn

    # S3 object key prefix and error output prefix
    prefix              = "logs/${each.key}/!{timestamp:yyyy}/!{timestamp:MM}/!{timestamp:dd}/"
    error_output_prefix = "errors/${each.key}/!{firehose:error-output-type}/!{timestamp:yyyy}/!{timestamp:MM}/!{timestamp:dd}/"

    # Buffering hints for delivery to S3 (5 MB or 5 minutes)
    buffering_size      = 5
    buffering_interval  = 300
    compression_format  = "GZIP"

    # DISABLE Dynamic Partitioning
    dynamic_partitioning_configuration {
      enabled = false
    }

    processing_configuration {
      enabled = true

      # NATIVE PROCESSOR CHAIN
      # Step 1. Decompress the GZIP from CloudWatch
      processors {
        type = "Decompression"
        parameters {
          parameter_name  = "CompressionFormat"
          parameter_value = "GZIP"
        }
      }

      # Step 2. Extract the raw message text (This works natively now because we don't need to save the metadata!)
      processors {
        type = "CloudWatchLogProcessing"
        parameters {
          parameter_name  = "DataMessageExtraction"
          parameter_value = "true"
        }
      }

      # Step 3. Add Newline Delimiter to each record for proper S3 storage
      # However New line is default and if you add this it will show as an update each and every time!
      # processors {
      #   type = "AppendDelimiterToRecord"
      #   parameters {
      #     parameter_name  = "Delimiter"
      #     parameter_value = "\\n"
      #   }
      # }
    }

    # Enable logging for Firehose delivery errors
    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = "${var.env_name}-firehose-to-S3-Archive"
      log_stream_name = "S3Delivery"
    }
  }

  ## needs IAM role to be created first for Firehose to access S3
  depends_on = [
    aws_iam_role_policy.firehose_delivery_policy
  ]
}