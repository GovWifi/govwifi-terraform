resource "aws_s3_bucket" "canary_tests_bucket" {
  bucket = "govwifi-canarytests-logs-${var.env}"
}

resource "aws_s3_bucket_public_access_block" "canary_tests_bucket" {
  bucket = aws_s3_bucket.canary_tests_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "canary_tests_bucket_policy" {
  bucket = aws_s3_bucket.canary_tests_bucket.id

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Id": "SSEAndSSLPolicy",
    "Statement": [
        {
            "Sid": "DenyUnEncryptedObjectUploads",
            "Effect": "Deny",
            "Principal": "*",
            "Action": "s3:PutObject",
            "Resource": "${aws_s3_bucket.canary_tests_bucket.arn}/*",
            "Condition": {
                "StringNotEquals": {
                    "s3:x-amz-server-side-encryption": "aws:kms"
                }
            }
        },
        {
            "Sid": "DenyInsecureConnections",
            "Effect": "Deny",
            "Principal": "*",
            "Action": "s3:*",
            "Resource": "${aws_s3_bucket.canary_tests_bucket.arn}/*",
            "Condition": {
                "Bool": {
                    "aws:SecureTransport": "false"
                }
            }
        },
        {
            "Sid": "",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::${var.aws_account_id}:role/govwifi-crossaccount-tools-deploy"
            },
            "Action": [
                "s3:Get*",
                "s3:Put*"
            ],
            "Resource": "${aws_s3_bucket.canary_tests_bucket.arn}/*"
        },
        {
            "Sid": "",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::${var.aws_account_id}:role/govwifi-crossaccount-tools-deploy"
            },
            "Action": "s3:ListBucket",
            "Resource": "${aws_s3_bucket.canary_tests_bucket.arn}"
        }
    ]
}
POLICY

}

# Resource to avoid error "AccessControlListNotSupported: The bucket does not allow ACLs"
resource "aws_s3_bucket_ownership_controls" "canary_tests_bucket_acl" {
  bucket = aws_s3_bucket.canary_tests_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "canary_tests_bucket_acl" {
  bucket = aws_s3_bucket.canary_tests_bucket.id
  acl    = "private"

  depends_on = [aws_s3_bucket_ownership_controls.canary_tests_bucket_acl]
}
