resource "aws_s3_bucket" "codebuild_logs_bucket" {
  bucket = "govwifi-capacity-testing-codebuild-logs"
}

resource "aws_s3_bucket_public_access_block" "codebuild_logs_bucket_block" {
  bucket = aws_s3_bucket.codebuild_logs_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}