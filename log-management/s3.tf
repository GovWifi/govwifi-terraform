## S3 Bucket for log archive, created only in London (eu-west-2)
resource "aws_s3_bucket" "log_archive_bucket" {
  count = var.region == "eu-west-2" ? 1 : 0
  bucket        = local.log_archive_bucket_name
  force_destroy = true

  tags = {
    Name   = "${title(var.env)} log archive bucket"
    Region = var.region

  }
}

## using object_ownership to secure bucket access and disable ACLs
resource "aws_s3_bucket_ownership_controls" "log_archive_ownership" {
  count = var.region == "eu-west-2" ? 1 : 0
  bucket = aws_s3_bucket.log_archive_bucket[0].id
  rule {
    # Set to 'BucketOwnerPreferred' or 'ObjectWriter' to disable ACLs
    # using 'ObjectWriter' as Firehose writes new objects.
    object_ownership = "ObjectWriter"
  }
}

# S3 Bucket server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "log_bucket_encryption" {
  count = var.region == "eu-west-2" ? 1 : 0
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
  count = var.region == "eu-west-2" ? 1 : 0
  bucket = aws_s3_bucket.log_archive_bucket[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket public access block
resource "aws_s3_bucket_public_access_block" "log_bucket_block_public_access" {
  count = var.region == "eu-west-2" ? 1 : 0
  bucket = aws_s3_bucket.log_archive_bucket[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Lifecycle configuration for cost optimization
resource "aws_s3_bucket_lifecycle_configuration" "log_bucket_lifecycle" {
  count = var.region == "eu-west-2" ? 1 : 0
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
