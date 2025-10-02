resource "aws_iam_policy" "govwifi_codebuild_role_policy" {
  name = "GovwifiCodeBuildServiceRolePolicy"
  path = "/"

  policy = <<EOF
{
    "Statement": [
        {
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Effect": "Allow",
            "Resource": "*",
            "Sid": "CloudWatchLogsPolicy"
        },
        {
            "Action": [
                "s3:GetBucketAcl",
                "s3:GetBucketLocation",
                "s3:GetObject",
                "s3:GetObjectVersion",
                "s3:PutObject"
            ],
            "Effect": "Allow",
            "Resource": [
              "${aws_s3_bucket.smoke_tests_bucket.arn}",
              "${aws_s3_bucket.smoke_tests_bucket.arn}/*"
            ],
            "Sid": "SmoketestsStoreLogsPolicy"
        },
        {
            "Action": [
                "codecommit:GitPull"
            ],
            "Effect": "Allow",
            "Resource": "*",
            "Sid": "CodeCommitPolicy"
        },
        {
            "Action": [
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "ecr:GetAuthorizationToken"

            ],
            "Effect": "Allow",
            "Resource": "*",
            "Sid": "ECRPullPolicy"
        }
    ],
    "Version": "2012-10-17"
}
EOF

}

resource "aws_iam_role_policy_attachment" "govwifi_codebuild_role_policy" {
  role       = var.govwifi_codebuild_role_name
  policy_arn = aws_iam_policy.govwifi_codebuild_role_policy.arn
}

resource "aws_iam_policy" "crossaccount_tools" {
  name        = "govwifi-crossaccount-tools-run-smoke-tests"
  path        = "/"
  description = "Allows AWS Tools account to run smoke-tests"

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:Get*",
                "s3:List*"
            ],
            "Resource": [
                "arn:aws:s3:::govwifi-codepipeline-bucket",
                "arn:aws:s3:::govwifi-codepipeline-bucket/*"
            ]
        },
        {
            "Sid": "AllowUseOfKeyInAccountTools",
            "Effect": "Allow",
            "Action": [
                "kms:Encrypt",
                "kms:Decrypt",
                "kms:ReEncrypt*",
                "kms:GenerateDataKey*",
                "kms:DescribeKey"
            ],
            "Resource": [
                "arn:aws:kms:eu-west-2:${data.aws_secretsmanager_secret_version.tools_account.secret_string}:key/${data.aws_secretsmanager_secret_version.tools_kms_key.secret_string}"
            ]
        },
        {
            "Sid": "ECRRepositoryPolicy",
            "Effect": "Allow",
            "Action": [
                "ecr:DescribeImages",
                "ecr:DescribeRepositories"
            ],
            "Resource": "arn:aws:ecr:eu-west-2:${data.aws_secretsmanager_secret_version.tools_account.secret_string}:govwifi/*"
        }
    ]
}
POLICY

}

resource "aws_iam_role_policy_attachment" "crossaccount_tools" {
  role       = var.govwifi_codebuild_role_name
  policy_arn = aws_iam_policy.govwifi_codebuild_role_policy.arn
}


resource "aws_iam_policy" "govwifi_codebuild_vpc_policy" {
  name = "GovwifiVPC"
  path = "/"

  policy = <<EOF
{
	"Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateNetworkInterface",
        "ec2:DescribeDhcpOptions",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DeleteNetworkInterface",
        "ec2:DescribeSubnets",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeVpcs"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateNetworkInterfacePermission"
      ],
      "Resource": "arn:aws:ec2:eu-west-2:${var.aws_account_id}:network-interface/*",
      "Condition": {
        "StringEquals": {
          "ec2:AuthorizedService": "codebuild.amazonaws.com"
        },
        "ArnEquals": {
          "ec2:Subnet": [
            "arn:aws:ec2:eu-west-2:${var.aws_account_id}:subnet/${var.smoketest_subnet_private_a}",
            "arn:aws:ec2:eu-west-2:${var.aws_account_id}:subnet/${var.smoketest_subnet_private_b}"
          ]
        }
      }
    }
  ]
}
EOF

}

resource "aws_iam_role_policy_attachment" "codebuild_vpc" {
  role       = var.govwifi_codebuild_role_name
  policy_arn = aws_iam_policy.govwifi_codebuild_vpc_policy.arn
}


resource "aws_iam_role" "iam_for_lambda" {
  count = var.create_slack_alert
  name  = "govwifi-smoke-tests-alert-lambda"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "lambda.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF

}


resource "aws_iam_policy" "iam_for_lambda" {
  count = var.create_slack_alert
  name  = "govwifi-smoke-tests-alert-lambda"
  path  = "/"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "logs:CreateLogGroup",
            "Resource": "arn:aws:logs:eu-west-2:${var.aws_account_id}:*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": [
                "arn:aws:logs:eu-west-2:${var.aws_account_id}:log-group:/aws/lambda/${aws_lambda_function.slack_alert[0].function_name}:*"
            ]
        }
    ]
}
EOF

}


resource "aws_iam_role_policy_attachment" "slack_alert" {
  count      = var.create_slack_alert
  role       = aws_iam_role.iam_for_lambda[0].name
  policy_arn = aws_iam_policy.iam_for_lambda[0].arn
}
