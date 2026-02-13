resource "aws_kinesis_firehose_delivery_stream" "cloudwatch_to_s3" {
  ## create a stream for each log group defined in locals
  for_each = local.log_groups

  # Unique name for each stream (e.g., firehose-api-gateway, firehose-backend)
  name        = "CW-log-archive-for-${each.key}"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn   = aws_iam_role.firehose_delivery_role.arn
    bucket_arn = local.log_archive_bucket_arn

    # S3 object key prefix and error output prefix
    prefix              = "logs/${var.region}/${each.key}/!{timestamp:yyyy}/!{timestamp:MM}/!{timestamp:dd}/"
    error_output_prefix = "errors/${var.region}/${each.key}/!{firehose:error-output-type}/!{timestamp:yyyy}/!{timestamp:MM}/!{timestamp:dd}/"

    # Buffering hints for delivery to S3 (64 MB or 15 minutes)
    buffering_size     = 64  # 64 MB ensure the files are of reasonable size for compression
    buffering_interval = 900 # 15 minutes (900 seconds)
    compression_format = "GZIP"

    # DISABLE Dynamic Partitioning
    dynamic_partitioning_configuration {
      enabled = false
    }

    processing_configuration {
      enabled = true

      processors {
        type = "Decompression"
        parameters {
          parameter_name  = "CompressionFormat"
          parameter_value = "GZIP"
        }
      }
    }

    # Enable logging for Firehose delivery errors
    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = "${var.env}-firehose-to-S3-Archive"
      log_stream_name = "S3Delivery"
    }
  }

  ## needs IAM role to be created first for Firehose to access S3
  depends_on = [
    aws_iam_role_policy.firehose_delivery_policy
  ]
}