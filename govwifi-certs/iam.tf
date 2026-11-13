data "aws_iam_policy_document" "renew_certs_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "renew_certs" {
  name               = "govwifi-renew-certs-codebuild-role"
  assume_role_policy = data.aws_iam_policy_document.renew_certs_assume_role.json
}

resource "aws_iam_role_policy" "renew_certs" {
  name = "govwifi-renew-certs-codebuild-policy"
  role = aws_iam_role.renew_certs.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "WriteBuildLogs",
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "${aws_cloudwatch_log_group.renew_certs.arn}:*"
    },
    {
      "Sid": "WriteRenewalStatus",
      "Effect": "Allow",
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::${data.aws_secretsmanager_secret_version.frontend_cert_bucket_london.secret_string}/cert_tests_to_delete/*"
    },
    {
      "Sid": "WriteCodeBuildS3Logs",
      "Effect": "Allow",
      "Action": [
        "s3:GetBucketAcl",
        "s3:GetBucketLocation"
      ],
      "Resource": "${aws_s3_bucket.renew_certs_bucket.arn}"
    },
    {
      "Sid": "UploadCodeBuildS3Logs",
      "Effect": "Allow",
      "Action": "s3:PutObject",
      "Resource": "${aws_s3_bucket.renew_certs_bucket.arn}/renew-certs-log/*"
    }
  ]
}
EOF
}