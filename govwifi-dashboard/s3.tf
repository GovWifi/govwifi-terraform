resource "aws_s3_bucket" "metrics_bucket" {
  bucket = "govwifi-${var.env_name}-metrics-bucket"

  tags = {
    Name = "${title(var.env_name)} Metrics data"
  }
}

resource "aws_s3_bucket_versioning" "metrics_bucket" {
  bucket = aws_s3_bucket.metrics_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "metrics_bucket" {
  bucket = aws_s3_bucket.metrics_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "export_data_bucket" {
  bucket = "govwifi-${var.env_name}-export-data-bucket"

  tags = {
    Name = "${title(var.env_name)} Exported metrics data"
  }
}

resource "aws_s3_bucket_versioning" "export_data_bucket" {
  bucket = aws_s3_bucket.export_data_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "export_data_bucket" {
  bucket = aws_s3_bucket.export_data_bucket.id

  block_public_acls   = false
  block_public_policy = false
}


resource "aws_s3_bucket_policy" "export_data_bucket_policy" {
  bucket = aws_s3_bucket.export_data_bucket.id

  policy = <<POLICY
  {
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicAccess",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::${aws_s3_bucket.export_data_bucket.id}/*"
        }
    ]
  }
  POLICY
}