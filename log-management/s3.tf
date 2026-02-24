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
  rule {
    id     = "log_lifecycle"
    status = "Enabled"

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
}

## Athena policy to access the log archive bucket
resource "aws_s3_bucket_policy" "log_archive_policy" {
  # Logic: Only apply if we created the bucket (London Only)
  count = var.region == "eu-west-2" ? 1 : 0

  bucket = aws_s3_bucket.log_archive_bucket[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowAthenaReads"
        Effect = "Allow"
        Principal = {
          "AWS" : "arn:aws:iam::${var.aws_account_id}:root"
        }
        Action = [
          "s3:GetBucketLocation",
          "s3:ListBucket",
          "s3:GetObject"
        ]
        Resource = [
          aws_s3_bucket.log_archive_bucket[0].arn,
          "${aws_s3_bucket.log_archive_bucket[0].arn}/logs/*",
          "${aws_s3_bucket.log_archive_bucket[0].arn}/cloudwatch-export/*"
        ]
      },
      {
        Sid    = "AllowAthenaResultWrites"
        Effect = "Allow"
        Principal = {
          "AWS" : "arn:aws:iam::${var.aws_account_id}:root"
        }
        Action = [
          "s3:PutObject",
          "s3:AbortMultipartUpload"
        ]
        Resource = [
          "${aws_s3_bucket.log_archive_bucket[0].arn}/athena-results/*"
        ]
      },
      # (Optional) Ensure SSL is required (Security Best Practice)
      {
        Sid       = "EnforceTLS"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.log_archive_bucket[0].arn,
          "${aws_s3_bucket.log_archive_bucket[0].arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}