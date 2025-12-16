resource "aws_s3_bucket" "log_archive_bucket" {
  bucket = "govwifi-${var.env_name}-log-archive"
  force_destroy = true

  tags = {
    Name   = "${title(var.env_name)} log archive bucket"
    Region = title(var.region)

  }
}

## using object_ownership to secure bucket access and disable ACLs
resource "aws_s3_bucket_ownership_controls" "log_archive_ownership" {
  bucket = aws_s3_bucket.log_archive_bucket.id
  rule {
    # Set to 'BucketOwnerPreferred' or 'ObjectWriter' to disable ACLs
    # using 'ObjectWriter' as Firehose writes new objects.
    object_ownership = "ObjectWriter"
  }
}

# S3 Bucket server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "log_bucket_encryption" {
  bucket = aws_s3_bucket.log_archive_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

## versioning enable to protect against accidental deletions
resource "aws_s3_bucket_versioning" "log_archive_bucket_versioning" {
  bucket = aws_s3_bucket.log_archive_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket public access block
resource "aws_s3_bucket_public_access_block" "log_bucket_pab" {
  bucket = aws_s3_bucket.log_archive_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Lifecycle configuration for cost optimization
resource "aws_s3_bucket_lifecycle_configuration" "log_bucket_lifecycle" {
  bucket = aws_s3_bucket.log_archive_bucket.id

  rule {
    id     = "log_lifecycle"
    status = "Enabled"

    # Transition to IA after 90 days
    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }

    # Transition to Glacier after 90 days
    transition {
      days          = 180
      storage_class = "GLACIER"
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