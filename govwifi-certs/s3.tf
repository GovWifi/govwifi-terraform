resource "aws_s3_bucket" "renew_certs_bucket" {
  bucket_prefix = "govwifi-renew-certs-logs"
}

resource "aws_s3_bucket_public_access_block" "renew_certs_bucket" {
  bucket = aws_s3_bucket.renew_certs_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "renew_certs_bucket" {
  bucket = aws_s3_bucket.renew_certs_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}