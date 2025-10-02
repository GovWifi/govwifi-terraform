resource "aws_iam_role" "govwifi_codebuild" {
  name = "govwifi-codebuild-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com",
				"AWS": [
						"arn:aws:iam::${data.aws_secretsmanager_secret_version.tools_account.secret_string}:role/govwifi-codepipeline-global-role"
					]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}


resource "aws_iam_role_policy_attachment" "govwifi_codebuild_role_deploy_policy" {
  role       = aws_iam_role.govwifi_codebuild.name
  policy_arn = aws_iam_policy.crossaccount_tools.arn
}


resource "aws_iam_role_policy_attachment" "crossaccount_tools_ecs_access_ecs_restart" {
  role       = aws_iam_role.govwifi_codebuild.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonECS_FullAccess"
}


resource "aws_iam_role_policy_attachment" "codepipeline_ssm_readonly" {
  role       = aws_iam_role.govwifi_codebuild.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "codebuild_start_build_perm" {
  role       = aws_iam_role.govwifi_codebuild.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeBuildDeveloperAccess"
}








resource "aws_iam_role" "crossaccount_tools" {
  name               = "govwifi-crossaccount-tools-deploy"
  assume_role_policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": [
										"arn:aws:iam::${data.aws_secretsmanager_secret_version.tools_account.secret_string}:role/govwifi-codepipeline-global-role"
                ]
            },
            "Action": "sts:AssumeRole",
            "Condition": {}
        }
    ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "crossaccount_tools" {
  role       = aws_iam_role.crossaccount_tools.name
  policy_arn = aws_iam_policy.crossaccount_tools.arn
}

resource "aws_iam_policy" "crossaccount_tools" {
  name        = "govwifi-crossaccount-tools-deploy"
  path        = "/"
  description = "Allows AWS Tools account to deploy new ECS tasks"

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::govwifi-codepipeline-bucket",
                "arn:aws:s3:::govwifi-codepipeline-bucket/*",
								"arn:aws:s3:::govwifi-codepipeline-bucket-ireland",
								"arn:aws:s3:::govwifi-codepipeline-bucket-ireland/*"
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
                "arn:aws:kms:eu-west-2:${data.aws_secretsmanager_secret_version.tools_account.secret_string}:key/${data.aws_secretsmanager_secret_version.tools_kms_key.secret_string}",
								"arn:aws:kms:eu-west-1:${data.aws_secretsmanager_secret_version.tools_account.secret_string}:key/${data.aws_secretsmanager_secret_version.tools_kms_key_ireland.secret_string}"
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

resource "aws_iam_role_policy_attachment" "crossaccount_tools_ecs_access" {
  role       = aws_iam_role.crossaccount_tools.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonECS_FullAccess"
}