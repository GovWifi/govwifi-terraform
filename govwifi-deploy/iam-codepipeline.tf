resource "aws_iam_role" "govwifi_codepipeline_global_role" {
  name               = "govwifi-codepipeline-global-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}


resource "aws_iam_role_policy" "codepipeline_global_policy" {
  name = "govwifi-codepipeline-global-policy"
  role = aws_iam_role.govwifi_codepipeline_global_role.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:*"
            ],
            "Resource": [
								"${aws_s3_bucket.codepipeline_bucket.arn}",
								"${aws_s3_bucket.codepipeline_bucket.arn}/*",
								"${aws_s3_bucket.codepipeline_bucket_ireland.arn}",
								"${aws_s3_bucket.codepipeline_bucket_ireland.arn}/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "codebuild:BatchGetBuilds",
                "codebuild:StartBuild"
            ],
            "Resource": "*"
        },
        {
            "Action": [
                "sts:AssumeRole"
            ],
            "Resource": [
								"arn:aws:iam::${local.aws_staging_account_id}:role/govwifi-crossaccount-tools-deploy",
								"arn:aws:iam::${local.aws_staging_account_id}:role/govwifi-codebuild-role",
                "arn:aws:iam::${local.aws_alpaca_account_id}:role/govwifi-crossaccount-tools-deploy",
								"arn:aws:iam::${local.aws_alpaca_account_id}:role/govwifi-codebuild-role",
                "arn:aws:iam::${local.aws_development_account_id}:role/govwifi-crossaccount-tools-deploy",
								"arn:aws:iam::${local.aws_development_account_id}:role/govwifi-codebuild-role",
								"arn:aws:iam::${local.aws_production_account_id}:role/govwifi-crossaccount-tools-deploy",
								"arn:aws:iam::${local.aws_production_account_id}:role/govwifi-codebuild-role"
							],
            "Effect": "Allow"
        }
    ]
}
EOF
}


### All environments

resource "aws_iam_policy" "govwifi_pipeline_role_additional_policy" {
  name = "govwifi-additional-policy-for-codepipeline"
  path = "/"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
						"Action": [
                "kms:GenerateDataKey",
                "kms:Decrypt"
            ],
            "Resource": "*"
        },
				{
						"Sid": "",
						"Effect": "Allow",
						"Action": "ecr:DescribeImages",
						"Resource": "*"
				}
    ]
}
EOF
}

resource "aws_iam_policy_attachment" "govwifi_pipeline_role_additional_policy" {
  name       = "govwifi-additional-policy-for-codepipeline"
  roles      = [aws_iam_role.govwifi_codepipeline_global_role.name]
  policy_arn = aws_iam_policy.govwifi_pipeline_role_additional_policy.arn
}

resource "aws_iam_policy_attachment" "codepipeline_kms_power_user" {
  name       = "codepipeline-kms-power-user_staging"
  roles      = [aws_iam_role.govwifi_codepipeline_global_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AWSKeyManagementServicePowerUser"
}

resource "aws_iam_policy_attachment" "codepipeline_ecr_power_user" {
  name       = "codepipeline-ecr-power-user"
  roles      = [aws_iam_role.govwifi_codepipeline_global_role.name, aws_iam_role.govwifi_codebuild.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}
