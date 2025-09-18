resource "aws_iam_role" "govwifi_codebuild" {
  name = "govwifi-codebuild-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}


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
                "codecommit:GitPull"
            ],
            "Effect": "Allow",
            "Resource": "*",
            "Sid": "CodeCommitPolicy"
        },
        {
            "Action": [
                "s3:GetObject",
                "s3:GetObjectVersion",
                "s3:PutObject",
                "s3:GetBucketAcl",
                "s3:GetBucketLocation"
            ],
            "Effect": "Allow",
            "Resource": "*",
            "Sid": "S3ObjectPolicy"
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
        },
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
          "Sid": "SecretManagerAccess",
          "Effect": "Allow",
          "Action": [
            "secretsmanager:GetSecretValue"
          ],
          "Resource": [
            "${data.aws_secretsmanager_secret_version.docker_hub_authtoken.arn}",
            "${data.aws_secretsmanager_secret_version.docker_hub_username.arn}"
          ]
        }
    ],
    "Version": "2012-10-17"
}
EOF
}

resource "aws_iam_policy_attachment" "govwifi_codebuild_role_policy" {
  name       = "govwifi-codebuild-role-policy"
  roles      = [aws_iam_role.govwifi_codebuild.name]
  policy_arn = aws_iam_policy.govwifi_codebuild_role_policy.arn
}


resource "aws_iam_policy_attachment" "codepipeline_ssm_readonly" {
  name       = "codepipeline-ssm-readonly"
  roles      = [aws_iam_role.govwifi_codebuild.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
}

resource "aws_iam_policy_attachment" "codebuild_start_build_perm" {
  name       = "codebuild-startbuild-perm"
  roles      = [aws_iam_role.govwifi_codebuild.name]
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeBuildDeveloperAccess"
}