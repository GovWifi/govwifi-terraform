resource "aws_s3_bucket" "codepipeline_bucket" {
  bucket = "govwifi-codepipeline-bucket"
}

resource "aws_s3_bucket_ownership_controls" "codepipeline_bucket" {
  bucket = aws_s3_bucket.codepipeline_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "codepipeline_bucket_acl" {
  bucket = aws_s3_bucket.codepipeline_bucket.id
  acl    = "private"

  depends_on = [aws_s3_bucket_ownership_controls.codepipeline_bucket]
}

resource "aws_s3_bucket_public_access_block" "codepipeline_bucket" {
  bucket = aws_s3_bucket.codepipeline_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "source" {
  bucket = aws_s3_bucket.codepipeline_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Push S3 notifications to EventBridge
resource "aws_s3_bucket_notification" "codepipeline_bucket" {
  bucket      = aws_s3_bucket.codepipeline_bucket.id
  eventbridge = true
}

resource "aws_s3_bucket_policy" "codepipeline_bucket_policy" {
  bucket = aws_s3_bucket.codepipeline_bucket.id

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Id": "SSEAndSSLPolicy",
    "Statement": [
        {
            "Sid": "DenyInsecureConnections",
            "Effect": "Deny",
            "Principal": "*",
            "Action": "s3:*",
            "Resource": "${aws_s3_bucket.codepipeline_bucket.arn}/*",
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
                "AWS": [
                      "arn:aws:iam::${local.aws_staging_account_id}:role/govwifi-crossaccount-tools-deploy",
                      "arn:aws:iam::${local.aws_staging_account_id}:role/govwifi-codebuild-role",
                      "arn:aws:iam::${local.aws_production_account_id}:role/govwifi-crossaccount-tools-deploy",
                      "arn:aws:iam::${local.aws_production_account_id}:role/govwifi-codebuild-role",
                      "arn:aws:iam::${local.aws_alpaca_account_id}:role/govwifi-crossaccount-tools-deploy",
                      "arn:aws:iam::${local.aws_alpaca_account_id}:role/govwifi-codebuild-role",
                      "${aws_iam_role.govwifi_codepipeline_global_role.arn}"
									]
            },
            "Action": [
                "s3:GetObject",
                "s3:ListBucket"
            ],
            "Resource": [
								"${aws_s3_bucket.codepipeline_bucket.arn}/*", "${aws_s3_bucket.codepipeline_bucket.arn}"
							]
        }
    ]
}
POLICY

}

resource "aws_s3_bucket" "codepipeline_bucket_ireland" {
  provider = aws.dublin
  bucket   = "govwifi-codepipeline-bucket-ireland"
}

resource "aws_s3_bucket_acl" "codepipeline_bucket_acl_ireland" {
  provider = aws.dublin
  bucket   = aws_s3_bucket.codepipeline_bucket_ireland.id
  acl      = "private"
}

resource "aws_s3_bucket_public_access_block" "codepipeline_bucket_ireland" {
  bucket = aws_s3_bucket.codepipeline_bucket_ireland.id

  provider                = aws.dublin
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


resource "aws_s3_bucket_versioning" "destination" {
  provider = aws.dublin
  bucket   = aws_s3_bucket.codepipeline_bucket_ireland.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_policy" "codepipeline_bucket_policy_ireland" {
  provider = aws.dublin
  bucket   = aws_s3_bucket.codepipeline_bucket_ireland.id

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Id": "SSEAndSSLPolicy",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Principal": {
                "AWS": [
										"arn:aws:iam::${local.aws_staging_account_id}:role/govwifi-crossaccount-tools-deploy",
										"arn:aws:iam::${local.aws_staging_account_id}:role/govwifi-codebuild-role",
										"arn:aws:iam::${local.aws_production_account_id}:role/govwifi-crossaccount-tools-deploy",
										"arn:aws:iam::${local.aws_production_account_id}:role/govwifi-codebuild-role",
                    "arn:aws:iam::${local.aws_alpaca_account_id}:role/govwifi-crossaccount-tools-deploy",
                    "arn:aws:iam::${local.aws_alpaca_account_id}:role/govwifi-codebuild-role",
										"${aws_iam_role.govwifi_codepipeline_global_role.arn}"
									]
            },
            "Action": [
                "s3:*"
            ],
            "Resource": [
								"${aws_s3_bucket.codepipeline_bucket_ireland.arn}/*", "${aws_s3_bucket.codepipeline_bucket_ireland.arn}"
							]
        }
    ]
}
POLICY

}
