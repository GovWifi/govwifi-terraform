resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "ecsTaskExecutionRole-${var.rack_env}-${var.aws_region_name}"
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
  name   = "${var.aws_region_name}-api-cluster-access-secrets-manager-${var.env_name}"
  role   = aws_iam_role.ecs_task_execution_role.id
  policy = data.aws_iam_policy_document.secrets_manager_policy.json
}

data "aws_iam_policy_document" "secrets_manager_policy" {
  statement {
    actions = [
      "secretsmanager:GetSecretValue"
    ]

    resources = [
      data.aws_secretsmanager_secret.users_db.arn,
      data.aws_secretsmanager_secret.session_db.arn,
      data.aws_secretsmanager_secret.admin_db.arn,
      data.aws_secretsmanager_secret.notify_api_key.arn,
      data.aws_secretsmanager_secret.notify_bearer_token.arn,
      data.aws_secretsmanager_secret.database_s3_encryption.arn,
      data.aws_secretsmanager_secret.safe_restarter_sentry_dsn.arn,
      data.aws_secretsmanager_secret.authentication_api_sentry_dsn.arn,
      data.aws_secretsmanager_secret.user_signup_api_sentry_dsn.arn,
      data.aws_secretsmanager_secret.logging_api_sentry_dsn.arn,
      data.aws_secretsmanager_secret.notify_do_not_reply.arn,
      data.aws_secretsmanager_secret.notify_support_reply.arn
    ]
  }
}


resource "aws_iam_user" "govwifi_deploy_pipeline" {
  count         = var.create_wordlist_bucket ? 1 : 0
  name          = "govwifi-deploy-pipeline"
  path          = "/"
  force_destroy = false
}

resource "aws_iam_policy" "read_wordlist_policy" {
  count       = var.create_wordlist_bucket ? 1 : 0
  name        = "read-wordlist-policy"
  path        = "/"
  description = "Allows deploy pipeline group to read wordlist"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "readWordListPolicy0",
      "Effect": "Allow",
      "Action": [
        "s3:ListBucketVersions",
        "s3:GetBucketVersioning",
        "s3:ListBucket"
      ],
      "Resource": "${aws_s3_bucket.wordlist[0].arn}"
    },
    {
      "Sid": "readWordListPolicy1",
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:PutObjectAcl",
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:PutObjectVersionAcl"
      ],
      "Resource": "${aws_s3_bucket.wordlist[0].arn}/*"
    }
  ]
}
POLICY

}


resource "aws_iam_policy" "read_ssm_parameters" {
  count = var.create_wordlist_bucket ? 1 : 0

  name        = "read-parameters"
  path        = "/"
  description = "Allows deploy pipeline user to read parameters"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "readSSMParameters",
      "Effect": "Allow",
      "Action": [
        "ssm:GetParameter"
      ],
      "Resource": "arn:aws:ssm:*:${var.aws_account_id}:parameter/govwifi-terraform/*"
    }
  ]
}
POLICY

}

resource "aws_iam_user_policy_attachment" "govwifi_read_wordlist_policy_attachment" {
  count      = var.create_wordlist_bucket ? 1 : 0
  user       = aws_iam_user.govwifi_deploy_pipeline[0].name
  policy_arn = aws_iam_policy.read_wordlist_policy[0].arn
}

resource "aws_iam_user_policy_attachment" "govwifi_read_ssm_parameters_policy_attachment" {
  count      = var.create_wordlist_bucket ? 1 : 0
  user       = aws_iam_user.govwifi_deploy_pipeline[0].name
  policy_arn = aws_iam_policy.read_ssm_parameters[0].arn
}

resource "aws_iam_user_policy_attachment" "govwifi_ecs_policy_attachment" {
  count      = var.create_wordlist_bucket ? 1 : 0
  user       = aws_iam_user.govwifi_deploy_pipeline[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceEventsRole"
}

resource "aws_iam_user_policy_attachment" "govwifi_ecr_policy_attachment" {
  count      = var.create_wordlist_bucket ? 1 : 0
  user       = aws_iam_user.govwifi_deploy_pipeline[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

resource "aws_iam_user_policy_attachment" "govwifi_deploy_pipeline_policy_attachment" {
  count      = var.create_wordlist_bucket ? 1 : 0
  user       = aws_iam_user.govwifi_deploy_pipeline[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonECS_FullAccess"
}

resource "aws_iam_role" "iam_for_user_api_sns_lambda" {
  count = var.user_signup_enabled
  name  = "iam_for_user_api_sns_lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_service_role" {
  count      = var.user_signup_enabled
  role       = aws_iam_role.iam_for_user_api_sns_lambda[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
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

## Scheduled Tasks
resource "aws_iam_role" "logging_scheduled_task_role" {
  count = var.logging_enabled
  name  = "${var.env_name}-logging-scheduled-task-role"

  assume_role_policy = <<DOC
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "events.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
DOC

}

resource "aws_iam_role_policy" "logging_scheduled_task_policy" {
  count = var.logging_enabled
  name  = "${var.env_name}-logging-scheduled-task-policy"
  role  = aws_iam_role.logging_scheduled_task_role[0].id

  policy = <<DOC
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "ecs:RunTask",
            "Resource": "${replace(
  aws_ecs_task_definition.logging_api_scheduled_task[0].arn,
  "/:\\d+$/",
  ":*",
)}"
        },
        {
          "Effect": "Allow",
          "Action": "iam:PassRole",
          "Resource": [
            "*"
          ],
          "Condition": {
            "StringLike": {
              "iam:PassedToService": "ecs-tasks.amazonaws.com"
            }
          }
        }
    ]
}
DOC

}

resource "aws_cloudwatch_event_target" "logging_daily_session_deletion" {
  count     = var.logging_enabled
  target_id = "${var.env_name}-logging-daily-session-deletion"
  arn       = aws_ecs_cluster.api_cluster.arn
  rule      = aws_cloudwatch_event_rule.daily_session_deletion_event[0].name
  role_arn  = aws_iam_role.logging_scheduled_task_role[0].arn

  ecs_target {
    task_count          = 1
    task_definition_arn = aws_ecs_task_definition.logging_api_scheduled_task[0].arn
    launch_type         = "FARGATE"
    platform_version    = "1.4.0"

    network_configuration {
      subnets = var.subnet_ids

      security_groups = concat(
        [aws_security_group.api_in.id],
        [aws_security_group.api_out.id]
      )

      assign_public_ip = true
    }
  }

  input = <<EOF
{
  "containerOverrides": [
    {
      "name": "logging-api",
      "command": ["bundle", "exec", "rake", "daily_session_deletion"]
    }
  ]
}
EOF

}


