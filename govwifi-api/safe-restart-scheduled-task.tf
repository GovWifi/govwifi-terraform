resource "aws_cloudwatch_event_rule" "daily_safe_restart" {
  count               = var.safe_restart_enabled
  name                = "${var.env_name}-daily-safe-restart"
  description         = "Triggers at 1am Daily"
  schedule_expression = "cron(0 1 * * ? *)"
  is_enabled          = true
}

resource "aws_cloudwatch_log_group" "safe_restart_log_group" {
  count = var.safe_restart_enabled
  name  = "${var.env_name}-safe-restart-docker-log-group"

  retention_in_days = 30
}

resource "aws_ecs_task_definition" "safe_restart_task_definition" {
  count                    = var.safe_restart_enabled
  family                   = "safe-restart-task-${var.env_name}"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.safe_restart_task_role[0].arn
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
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
          "hostPort": 8080,
          "containerPort": 8080,
          "protocol": "tcp"
        }
      ],
      "hostname": null,
      "essential": true,
      "entryPoint": null,
      "mountPoints": [],
      "name": "safe-restart",
      "ulimits": null,
      "dockerSecurityOptions": null,
      "environment": [
        {
          "name": "RACK_ENV",
          "value": "${var.rack_env}"
        },{
          "name": "SENTRY_CURRENT_ENV",
          "value": "${var.sentry_current_env}"
        }
      ],
      "secrets": [
        {
          "name": "SENTRY_DSN",
          "valueFrom": "${data.aws_secretsmanager_secret.safe_restarter_sentry_dsn.arn}"
        }
      ],
      "links": null,
      "workingDirectory": null,
      "readonlyRootFilesystem": null,
      "image": "${local.safe_restart_docker_image_new}",
      "command": null,
      "user": null,
      "dockerLabels": null,
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "${aws_cloudwatch_log_group.safe_restart_log_group[0].name}",
          "awslogs-region": "${var.aws_region}",
          "awslogs-stream-prefix": "${var.env_name}-safe-restart-docker-logs"
        }
      },
      "cpu": 0,
      "privileged": null,
      "expanded": true
    }
]
EOF

}

resource "aws_iam_role" "safe_restart_task_role" {
  count = var.safe_restart_enabled
  name  = "${var.env_name}-safe-restart-task-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

}

resource "aws_iam_role" "safe_restart_scheduled_task_role" {
  count = var.safe_restart_enabled
  name  = "${var.env_name}-safe-restart-scheduled-task-role"

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

resource "aws_iam_role_policy" "safe_restart_task_policy" {
  count      = var.safe_restart_enabled
  name       = "${var.env_name}-safe-restart-task-policy"
  role       = aws_iam_role.safe_restart_task_role[0].id
  depends_on = [aws_iam_role.safe_restart_task_role]

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecs:ListClusters",
        "ecs:ListTasks",
        "ecs:StopTask",
        "route53:ListHealthChecks",
        "route53:GetHealthCheckStatus"
      ],
      "Resource": "*"
    }
  ]
}
EOF

}

resource "aws_iam_role_policy" "safe_restart_scheduled_task_policy" {
  count = var.safe_restart_enabled
  name  = "${var.env_name}-safe-restart-scheduled-task-policy"
  role  = aws_iam_role.safe_restart_scheduled_task_role[0].id

  policy = <<DOC
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "ecs:RunTask",
            "Resource": "${replace(
  aws_ecs_task_definition.safe_restart_task_definition[0].arn,
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

resource "aws_cloudwatch_event_target" "daily_safe_restart" {
  count     = var.safe_restart_enabled
  target_id = "${var.env_name}-safe-restart"
  arn       = aws_ecs_cluster.api_cluster.arn
  rule      = aws_cloudwatch_event_rule.daily_safe_restart[0].name
  role_arn  = aws_iam_role.safe_restart_scheduled_task_role[0].arn

  ecs_target {
    task_count          = 1
    task_definition_arn = aws_ecs_task_definition.safe_restart_task_definition[0].arn
    launch_type         = "FARGATE"
    platform_version    = "1.4.0"

    network_configuration {
      subnets = var.subnet_ids

      security_groups = concat(
        var.backend_sg_list,
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
      "name": "safe-restart",
      "command": ["bundle", "exec", "rake", "safe_restart[${var.rack_env}]"]
    }
  ]
}
EOF

}
