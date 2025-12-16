# IAM role for Firehose
resource "aws_iam_role" "firehose_delivery_role" {
  name = "${var.env_name}-firehose-delivery-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "firehose.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "Firehose Delivery Role"
    Environment = var.env_name
  }
}

# IAM policy for Firehose to access S3
resource "aws_iam_role_policy" "firehose_delivery_policy" {
  name = "${var.env_name}-firehose-delivery-policy"
  role = aws_iam_role.firehose_delivery_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:AbortMultipartUpload",
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:PutObject"
        ]
        Resource = [
          "${aws_s3_bucket.log_archive_bucket.arn}",
          "${aws_s3_bucket.log_archive_bucket.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.firehose_error_log_group.arn}"

      }
    ]
  })
}

# IAM role for CloudWatch Logs to access Firehose
resource "aws_iam_role" "logs_to_firehose_role" {
  name = "${var.env_name}-cloudwatch-logs-firehose-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "logs.${var.region}.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "CloudWatch Logs Firehose Role"
    Environment = var.env_name
  }
}

# IAM policy for CloudWatch Logs to put records to Firehose
resource "aws_iam_role_policy" "cloudwatch_logs_firehose_policy" {
  name = "${var.env_name}-cloudwatch-logs-firehose-policy"
  role = aws_iam_role.logs_to_firehose_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "firehose:PutRecord",
          "firehose:PutRecordBatch"
        ]
        Resource = "${aws_kinesis_firehose_delivery_stream.cloudwatch_to_s3.arn}"
      }
    ]
  })
}




