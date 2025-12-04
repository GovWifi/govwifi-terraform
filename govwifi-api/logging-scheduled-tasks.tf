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

resource "aws_cloudwatch_event_target" "gdpr_set_user_last_login" {
  count     = var.logging_enabled
  target_id = "${var.env_name}-gdpr-user-set-last-login"
  arn       = aws_ecs_cluster.api_cluster.arn
  rule      = aws_cloudwatch_event_rule.daily_gdpr_set_user_last_login[0].name
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
      "command": ["bundle", "exec", "rake", "update_yesterdays_last_login"]
    }
  ]
}
EOF

}

resource "aws_cloudwatch_event_target" "hourly_request_statistics" {
  count     = var.logging_enabled
  target_id = "${var.env_name}-publish-hourly-request-statistics"
  arn       = aws_ecs_cluster.api_cluster.arn
  rule      = aws_cloudwatch_event_rule.hourly_request_statistics_event[0].name
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
      "command": ["bundle", "exec", "rake", "send_request_statistics"]
    }
  ]
}
EOF

}

# new metrics
resource "aws_cloudwatch_event_target" "publish_monthly_metrics_logging" {
  count     = var.logging_enabled
  target_id = "${var.env_name}-logging-monthly-metrics"
  arn       = aws_ecs_cluster.api_cluster.arn
  rule      = aws_cloudwatch_event_rule.monthly_metrics_logging_event[0].name
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
      "command": ["bundle", "exec", "rake", "publish_monthly_metrics"]
    }
  ]
}
EOF

}

resource "aws_cloudwatch_event_target" "publish_weekly_metrics_logging" {
  count     = var.logging_enabled
  target_id = "${var.env_name}-logging-weekly-metrics"
  arn       = aws_ecs_cluster.api_cluster.arn
  rule      = aws_cloudwatch_event_rule.weekly_metrics_logging_event[0].name
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
      "command": ["bundle", "exec", "rake", "publish_weekly_metrics"]
    }
  ]
}
EOF

}

resource "aws_cloudwatch_event_target" "publish_daily_metrics_logging" {
  count     = var.logging_enabled
  target_id = "${var.env_name}-logging-daily-metrics"
  arn       = aws_ecs_cluster.api_cluster.arn
  rule      = aws_cloudwatch_event_rule.daily_metrics_logging_event[0].name
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
      "command": ["bundle", "exec", "rake", "publish_daily_metrics"]
    }
  ]
}
EOF

}


resource "aws_cloudwatch_event_target" "publish_metrics_to_data_bucket" {
  count     = var.logging_enabled
  target_id = "${var.env_name}-logging-publish-metrics-to-data-bucket"
  arn       = aws_ecs_cluster.api_cluster.arn
  rule      = aws_cloudwatch_event_rule.weekly_metrics_logging_event[0].name
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
      "command": ["bundle", "exec", "rake", "sync_s3_to_data_bucket[${var.metrics_bucket_name}, ${var.export_data_bucket_name}]"]
    }
  ]
}
EOF

}

resource "aws_cloudwatch_event_target" "smoke_test_cleanup" {
  count     = var.logging_enabled
  target_id = "${var.env_name}-smoke-test-cleanup"
  arn       = aws_ecs_cluster.api_cluster.arn
  rule      = aws_cloudwatch_event_rule.daily_smoke_test_cleanup_event[0].name
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
      "command": ["bundle", "exec", "rake", "smoke_tests_cleanup"]
    }
  ]
}
EOF

}

resource "aws_ecs_task_definition" "logging_api_scheduled_task" {
  count                    = var.logging_enabled
  family                   = "logging-api-scheduled-task-${var.env_name}"
  task_role_arn            = aws_iam_role.logging_api_task_role[0].arn
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  requires_compatibilities = ["FARGATE"]
  cpu                      = 512
  memory                   = 1024
  network_mode             = "awsvpc"

  container_definitions = <<EOF
[
    {
      "volumesFrom": [],
      "memory": 950,
      "extraHosts": null,
      "dnsServers": null,
      "disableNetworking": null,
      "dnsSearchDomains": null,
      "portMappings": [
        {
          "hostPort": 8080,
          "containerPort": 8080,
          "protocol": "tcp"
        }
      ],
      "hostname": null,
      "essential": true,
      "entryPoint": null,
      "mountPoints": [],
      "name": "logging-api",
      "ulimits": null,
      "dockerSecurityOptions": null,
      "environment": [
        {
          "name": "DB_NAME",
          "value": "govwifi_${var.env_name}"
        },{
          "name": "DB_HOSTNAME",
          "value": "${var.db_hostname}"
        },{
          "name": "DB_READ_REPLICA_HOSTNAME",
          "value": "${var.db_read_replica_hostname}"
        },{
          "name": "USER_DB_NAME",
          "value": "govwifi_${var.env}_users"
        },{
          "name": "USER_DB_HOSTNAME",
          "value": "${var.user_db_hostname}"
        },{
          "name": "RACK_ENV",
          "value": "${var.rack_env}"
        },{
          "name": "SENTRY_CURRENT_ENV",
          "value": "${var.sentry_current_env}"
        },{
          "name": "ENVIRONMENT_NAME",
          "value": "${var.env_name}"
        },{
          "name": "S3_PUBLISHED_LOCATIONS_IPS_BUCKET",
          "value": "${var.admin_app_data_s3_bucket_name}"
        },{
          "name": "S3_PUBLISHED_LOCATIONS_IPS_OBJECT_KEY",
          "value": "ips-and-locations.json"
        },{
          "name": "S3_METRICS_BUCKET",
          "value": "${var.metrics_bucket_name}"
        },{
          "name": "VOLUMETRICS_ENDPOINT",
          "value": "https://${var.elasticsearch_endpoint}"
        },{
          "name": "SMOKE_TEST_IPS",
          "value": "${join(",", var.smoke_test_ips)}"
        }
      ],
      "secrets": [
        {
          "name": "DB_PASS",
          "valueFrom": "${data.aws_secretsmanager_secret_version.session_db.arn}:password::"
        },{
          "name": "DB_USER",
          "valueFrom": "${data.aws_secretsmanager_secret_version.session_db.arn}:username::"
        },{
          "name": "USER_DB_PASS",
          "valueFrom": "${data.aws_secretsmanager_secret_version.users_db.arn}:password::"
        },{
          "name": "USER_DB_USER",
          "valueFrom": "${data.aws_secretsmanager_secret_version.users_db.arn}:username::"
        },{
          "name": "SENTRY_DSN",
          "valueFrom": "${data.aws_secretsmanager_secret.logging_api_sentry_dsn.arn}"
        }
      ],
      "links": null,
      "workingDirectory": null,
      "readonlyRootFilesystem": null,
      "image": "${local.logging_docker_image_new}",
      "command": null,
      "user": null,
      "dockerLabels": null,
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "${aws_cloudwatch_log_group.logging_api_log_group[0].name}",
          "awslogs-region": "${var.aws_region}",
          "awslogs-stream-prefix": "${var.env_name}-logging-api-docker-logs"
        }
      },
      "cpu": 0,
      "privileged": null,
      "expanded": true
    }
]
EOF

}

resource "aws_cloudwatch_event_target" "sync_s3_to_elasticsearch" {
  count     = var.logging_enabled
  target_id = "${var.env_name}-sync-s3-to-elasticsearch"
  arn       = aws_ecs_cluster.api_cluster.arn
  rule      = aws_cloudwatch_event_rule.sync_s3_to_elasticsearch_event[0].name
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
      "command": ["bundle", "exec", "rake", "sync_s3_volumetrics"]
    }
  ]
}
EOF

}
