resource "aws_cloudwatch_event_target" "retrieve_notifications" {
  count     = var.user_signup_enabled
  target_id = "${var.env_name}-retrieve-notifications"
  arn       = aws_ecs_cluster.api_cluster.arn
  rule      = aws_cloudwatch_event_rule.retrieve_notifications_event[0].name
  role_arn  = aws_iam_role.user_signup_scheduled_task_role[0].arn

  ecs_target {
    task_count          = 1
    task_definition_arn = aws_ecs_task_definition.user_signup_api_scheduled_task[0].arn
    launch_type         = "FARGATE"
    platform_version    = "1.4.0"

    network_configuration {
      subnets = var.subnet_ids

      security_groups = concat(
        [aws_security_group.api_in.id],
        [aws_security_group.api_out.id],
      )

      assign_public_ip = true
    }
  }

  input = <<EOF
{
  "containerOverrides": [
    {
      "name": "user-signup-api",
      "command": ["bundle", "exec", "rake", "retrieve_notifications"]
    }
  ]
}
EOF

}

resource "aws_cloudwatch_event_target" "backup_notify_templates" {
  count     = var.user_signup_enabled
  target_id = "${var.env_name}-backup-notify-templates"
  arn       = aws_ecs_cluster.api_cluster.arn
  rule      = aws_cloudwatch_event_rule.backup_notify_templates_event[0].name
  role_arn  = aws_iam_role.user_signup_scheduled_task_role[0].arn

  ecs_target {
    task_count          = 1
    task_definition_arn = aws_ecs_task_definition.user_signup_api_scheduled_task[0].arn
    launch_type         = "FARGATE"
    platform_version    = "1.4.0"

    network_configuration {
      subnets = var.subnet_ids

      security_groups = concat(
        [aws_security_group.api_in.id],
        [aws_security_group.api_out.id],
      )

      assign_public_ip = true
    }
  }

  input = <<EOF
{
  "containerOverrides": [
    {
      "name": "user-signup-api",
      "command": ["bundle", "exec", "rake", "backup_notify_templates"]
    }
  ]
}
EOF

}

resource "aws_iam_role" "user_signup_scheduled_task_role" {
  count = var.user_signup_enabled
  name  = "${var.env_name}-user-signup-scheduled-task-role"

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

resource "aws_iam_role_policy" "user_signup_scheduled_task_policy" {
  count = var.user_signup_enabled
  name  = "${var.env_name}-user-signup-scheduled-task-policy"
  role  = aws_iam_role.user_signup_scheduled_task_role[0].id

  policy = <<DOC
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "ecs:RunTask",
            "Resource": "${replace(
  aws_ecs_task_definition.user_signup_api_scheduled_task[0].arn,
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

resource "aws_cloudwatch_event_target" "user_signup_daily_user_deletion" {
  count     = var.user_signup_enabled
  target_id = "${var.env_name}-user-signup-daily-cleanup"
  arn       = aws_ecs_cluster.api_cluster.arn
  rule      = aws_cloudwatch_event_rule.daily_user_deletion_event[0].name
  role_arn  = aws_iam_role.user_signup_scheduled_task_role[0].arn

  ecs_target {
    task_count          = 1
    task_definition_arn = aws_ecs_task_definition.user_signup_api_scheduled_task[0].arn
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
      "name": "user-signup-api",
      "command": ["bundle", "exec", "rake", "delete_inactive_users"]
    }
  ]
}
EOF

}

resource "aws_cloudwatch_event_target" "trim_sessions_database_table" {
  count     = var.user_signup_enabled
  target_id = "${var.env_name}-trim-sessions-database-table"
  arn       = aws_ecs_cluster.api_cluster.arn
  rule      = aws_cloudwatch_event_rule.trim_sessions_database_table_event[0].name
  role_arn  = aws_iam_role.user_signup_scheduled_task_role[0].arn

  ecs_target {
    task_count          = 1
    task_definition_arn = aws_ecs_task_definition.user_signup_api_scheduled_task[0].arn
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
      "name": "trim-sessions-database-table",
      "command": ["bundle", "exec", "rake", "db:sessions:trim"]
    }
  ]
}
EOF

}

resource "aws_ecs_task_definition" "user_signup_api_scheduled_task" {
  count                    = var.user_signup_enabled
  family                   = "user-signup-api-scheduled-task-${var.env_name}"
  task_role_arn            = aws_iam_role.user_signup_api_task_role[0].arn
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  requires_compatibilities = ["FARGATE"]
  cpu                      = 512
  memory                   = 1024
  network_mode             = "awsvpc"

  container_definitions = <<EOF
[
    {
      "volumesFrom": [],
      "memory": 1024,
      "extraHosts": null,
      "dnsServers": null,
      "disableNetworking": null,
      "dnsSearchDomains": null,
      "portMappings": [
        {
          "containerPort": 8080,
          "protocol": "tcp"
        }
      ],
      "hostname": null,
      "essential": true,
      "entryPoint": null,
      "mountPoints": [],
      "name": "user-signup-api",
      "ulimits": null,
      "dockerSecurityOptions": null,
      "environment": [
        {
          "name": "DB_NAME",
          "value": "govwifi_${var.env}_users"
        },{
          "name": "DB_HOSTNAME",
          "value": "${var.user_db_hostname}"
        },{
          "name": "RACK_ENV",
          "value": "${var.app_env}"
        },{
          "name": "SENTRY_CURRENT_ENV",
          "value": "${var.sentry_current_env}"
        },{
          "name": "ENVIRONMENT_NAME",
          "value": "${var.env_name}"
        },{
          "name": "FIRETEXT_TOKEN",
          "value": "${var.firetext_token}"
        },{
          "name": "S3_METRICS_BUCKET",
          "value": "${var.metrics_bucket_name}"
        },{
          "name": "S3_NOTIFICATION_TEMPLATES_BUCKET",
          "value": "govwifi-${var.env}-notification-templates"
        }
      ],
      "secrets": [
        {
          "name": "DB_PASS",
          "valueFrom": "${data.aws_secretsmanager_secret_version.users_db.arn}:password::"
        },{
          "name": "DB_USER",
          "valueFrom": "${data.aws_secretsmanager_secret_version.users_db.arn}:username::"
        },{
          "name": "NOTIFY_API_KEY",
          "valueFrom": "${data.aws_secretsmanager_secret_version.notify_api_key.arn}:notify-api-key::"
        },{
          "name": "NOTIFY_DO_NOT_REPLY",
          "valueFrom": "${data.aws_secretsmanager_secret.notify_do_not_reply.arn}"
        },{
          "name": "NOTIFY_SUPPORT_REPLY",
          "valueFrom": "${data.aws_secretsmanager_secret.notify_support_reply.arn}"
        },{
          "name": "GOVNOTIFY_BEARER_TOKEN",
          "valueFrom": "${data.aws_secretsmanager_secret_version.notify_bearer_token.arn}:token::"
        },{
          "name": "SENTRY_DSN",
          "valueFrom": "${data.aws_secretsmanager_secret.user_signup_api_sentry_dsn.arn}"
        }
      ],
      "links": null,
      "workingDirectory": null,
      "readonlyRootFilesystem": null,
      "image": "${local.user_signup_docker_image_new}",
      "command": null,
      "user": null,
      "dockerLabels": null,
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "${aws_cloudwatch_log_group.user_signup_api_log_group[0].name}",
          "awslogs-region": "${var.aws_region}",
          "awslogs-stream-prefix": "${var.env_name}-user-signup-api-docker-logs"
        }
      },
      "cpu": 0,
      "privileged": null,
      "expanded": true
    }
]
EOF

}

resource "aws_cloudwatch_event_target" "active_users_signup_surveys" {
  count     = var.user_signup_enabled
  target_id = "${var.env_name}-active-users-signup-surveys"
  arn       = aws_ecs_cluster.api_cluster.arn
  rule      = aws_cloudwatch_event_rule.active_users_signup_survey_event[0].name
  role_arn  = aws_iam_role.user_signup_scheduled_task_role[0].arn

  ecs_target {
    task_count          = 1
    task_definition_arn = aws_ecs_task_definition.user_signup_api_scheduled_task[0].arn
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
      "name": "user-signup-api",
      "command": ["bundle", "exec", "rake", "users_signup_survey:send_active"]
    }
  ]
}
EOF

}

resource "aws_cloudwatch_event_target" "inactive_user_followup" {
  count     = var.user_signup_enabled
  target_id = "${var.env_name}-inactive-user-followup"
  arn       = aws_ecs_cluster.api_cluster.arn
  rule      = aws_cloudwatch_event_rule.inactive_user_followup_event[0].name
  role_arn  = aws_iam_role.user_signup_scheduled_task_role[0].arn

  ecs_target {
    task_count          = 1
    task_definition_arn = aws_ecs_task_definition.user_signup_api_scheduled_task[0].arn
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
      "name": "inactive-user-followup",
      "command": ["bundle", "exec", "rake", "inactive_user_followup"]
    }
  ]
}
EOF

}
