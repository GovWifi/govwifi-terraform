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
resource "aws_iam_role_policy" "ecs_admin_instance_policy" {
  name       = "${var.aws_region_name}-ecs-admin-instance-policy-${var.env_name}"
  role       = aws_iam_role.ecs_admin_instance_role.id
  depends_on = [aws_s3_bucket.admin_bucket]

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecs:CreateCluster",
        "ecs:DeregisterContainerInstance",
        "ecs:DiscoverPollEndpoint",
        "ecs:Poll",
        "ecs:RegisterContainerInstance",
        "ecs:StartTelemetrySession",
        "ecs:Submit*",
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage"
      ],
      "Resource": [ "*" ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams"
      ],
      "Resource": [
        "arn:aws:logs:*:*:*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "cloudwatch:PutMetricData",
        "cloudwatch:GetMetricStatistics",
        "cloudwatch:ListMetrics",
        "ec2:DescribeTags"
      ],
      "Resource": "*"
    },{
      "Effect": "Allow",
      "Action": [
        "route53:ListHealthChecks",
        "route53:GetHealthCheckStatus"
      ],
      "Resource": "*"
    },{
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject"
      ],
      "Resource": ["${aws_s3_bucket.admin_bucket.arn}/*"]
    },{
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:PutObjectAcl",
        "s3:GetObject",
        "s3:GetObjectAcl",
        "s3:DeleteObject"
      ],
      "Resource": ["${aws_s3_bucket.admin_mou_bucket.arn}/*", "arn:aws:s3:::${var.frontend_cert_bucket}/*"]
    },{
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket"
      ],
      "Resource": ["${aws_s3_bucket.admin_mou_bucket.arn}"]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:PutObjectAcl",
        "s3:PutObjectVersionAcl"
      ],
      "Resource": ["${aws_s3_bucket.product_page_data_bucket.arn}/*"]
    }
  ]
}
EOF

}

resource "aws_iam_role" "ecs_admin_instance_role" {
  name = "${var.aws_region_name}-ecs-admin-instance-role-${var.env_name}"

  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

resource "aws_iam_role_policy" "allow_ssm" {
  name   = "${var.aws_region_name}-allow-ssm-${var.env_name}"
  role   = aws_iam_role.ecs_admin_instance_role.id
  policy = data.aws_iam_policy_document.allow_ssm.json
}

data "aws_iam_policy_document" "allow_ssm" {
  statement {
    actions = [
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel"
    ]

    resources = [
      "*"
    ]
  }
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "admin-ecsTaskExecutionRole-${var.app_env}-${var.aws_region_name}"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "secrets_manager_policy" {
  name   = "${var.aws_region_name}-admin-api-access-secrets-manager-${var.env_name}"
  role   = aws_iam_role.ecs_task_execution_role.id
  policy = data.aws_iam_policy_document.secrets_manager_policy.json
}

data "aws_iam_policy_document" "secrets_manager_policy" {
  statement {
    actions = [
      "secretsmanager:GetSecretValue"
    ]

    resources = [
      data.aws_secretsmanager_secret_version.notify_api_key.arn,
      data.aws_secretsmanager_secret_version.zendesk_api_token.arn,
      data.aws_secretsmanager_secret_version.key_base.arn,
      data.aws_secretsmanager_secret_version.otp_encryption_key.arn,
      data.aws_secretsmanager_secret_version.session_db.arn,
      data.aws_secretsmanager_secret_version.users_db.arn,
      data.aws_secretsmanager_secret_version.admin_db.arn,
      data.aws_secretsmanager_secret_version.google_service_account_backup_credentials.arn,
      data.aws_secretsmanager_secret.sentry_dsn.arn,
    ]
  }
}
