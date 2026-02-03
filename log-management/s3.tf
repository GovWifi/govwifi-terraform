## S3 Bucket for log archive, created only in London (eu-west-2)
resource "aws_s3_bucket" "log_archive_bucket" {
  count         = var.region == "eu-west-2" ? 1 : 0
  bucket        = local.log_archive_bucket_name
  force_destroy = true

  tags = {
    Name   = "${title(var.env)} log archive bucket"
    Region = var.region

  }
}

## using object_ownership to secure bucket access and disable ACLs
resource "aws_s3_bucket_ownership_controls" "log_archive_ownership" {
  count  = var.region == "eu-west-2" ? 1 : 0
  bucket = aws_s3_bucket.log_archive_bucket[0].id
  rule {
    # Set to 'BucketOwnerPreferred' or 'ObjectWriter' to disable ACLs
    # using 'ObjectWriter' as Firehose writes new objects.
    object_ownership = "ObjectWriter"
  }
}

# S3 Bucket server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "log_bucket_encryption" {
  count  = var.region == "eu-west-2" ? 1 : 0
  bucket = aws_s3_bucket.log_archive_bucket[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

## versioning enable to protect against accidental deletions
resource "aws_s3_bucket_versioning" "log_archive_bucket_versioning" {
  count  = var.region == "eu-west-2" ? 1 : 0
  bucket = aws_s3_bucket.log_archive_bucket[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket public access block
resource "aws_s3_bucket_public_access_block" "log_bucket_block_public_access" {
  count  = var.region == "eu-west-2" ? 1 : 0
  bucket = aws_s3_bucket.log_archive_bucket[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Lifecycle configuration for cost optimization
resource "aws_s3_bucket_lifecycle_configuration" "log_bucket_lifecycle" {
  count  = var.region == "eu-west-2" ? 1 : 0
  bucket = aws_s3_bucket.log_archive_bucket[0].id
  # -----------------------------------------------------------
  # RULE 1: Firehose Logs (Big files, Safe for IA)
  # -----------------------------------------------------------
  rule {
    id     = "log_lifecycle"
    status = "Enabled"
    # only for logs folder, as Historical Logs are < 128kb and thus would cost more to store in IA than standard
    filter {
      prefix = "logs/"
    }
    # Transition to IA after 30 days
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    # Delete after 1 year (365 days)
    expiration {
      days = 365
    }

    # Clean up incomplete multipart uploads
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
  # -----------------------------------------------------------
  # RULE 2: Historical Exports (Small files, Stay in Standard)
  # files < 128KB cost more in IA than Standard
  # -----------------------------------------------------------
  rule {
    id     = "historical_exports_lifecycle"
    status = "Enabled"

    filter {
      prefix = "cloudwatch-export/" # Only applies to the script data
    }

    # NO TRANSITION block here.
    # We keep these in 'Standard' to avoid the 128KB minimum charge
    # because CloudWatch creates thousands of tiny files.

    # Still Delete after 1 year (Compliance)
    expiration {
      days = 365
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

#### --- S3 bucket Policy, remove after export ---- ######

# --- BUCKET POLICY (For CloudWatch Export Script) ---
resource "aws_s3_bucket_policy" "allow_cloudwatch_exports" {
  # Only create this policy in the Primary Region (London)
  count = var.region == "eu-west-2" ? 1 : 0

  bucket = aws_s3_bucket.log_archive_bucket[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudWatchLogsExports"
        Effect = "Allow"
        Principal = {
          Service = "logs.amazonaws.com"
        }
        Action = [
          "s3:GetBucketAcl",
          "s3:PutObject"
        ]
        Resource = [
          aws_s3_bucket.log_archive_bucket[0].arn,
          "${aws_s3_bucket.log_archive_bucket[0].arn}/*"
        ]
        Condition = {
          # Security: Only allow logs from YOUR account ID
          StringEquals = {
            "aws:SourceAccount" = var.aws_account_id
          }
          # Flexible: Allow logs from ANY region (eu-west-1 or 2) in your account
          StringLike = {
            "aws:SourceArn" = "arn:aws:logs:*:${var.aws_account_id}:log-group:*"
          }
        }
      }
    ]
  })
}
