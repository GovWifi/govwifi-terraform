resource "aws_cloudwatch_log_group" "logging_api_log_group" {
  count = var.logging_enabled
  name  = "${var.env_name}-logging-api-docker-log-group"

  retention_in_days = var.log_retention
}

resource "aws_ecs_task_definition" "logging_api_task" {
  count                    = var.logging_enabled
  family                   = "logging-api-task-${var.env_name}"
  task_role_arn            = aws_iam_role.logging_api_task_role[0].arn
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  memory                   = 1024
  cpu                      = "512"
  network_mode             = "awsvpc"

  container_definitions = <<EOF
[
    {
      "volumesFrom": [],
      "cpu": 512,
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
          "name": "VOLUMETRICS_ENDPOINT",
          "value": "https://${var.elasticsearch_endpoint}"
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
      "privileged": null,
      "expanded": true
    }
]
EOF

}

resource "aws_ecs_service" "logging_api_service" {
  count            = var.logging_enabled
  name             = "logging-api-service-${var.env_name}"
  cluster          = aws_ecs_cluster.api_cluster.id
  task_definition  = aws_ecs_task_definition.logging_api_task[0].arn
  desired_count    = var.task_count_min
  launch_type      = "FARGATE"
  platform_version = "1.4.0"

  enable_execute_command = true

  health_check_grace_period_seconds = 20

  network_configuration {
    security_groups = concat(
      [aws_security_group.api_in.id],
      [aws_security_group.api_out.id],
      [aws_security_group.logging_api_service.id]
    )

    subnets          = var.subnet_ids
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.logging_api_tg[0].arn
    container_name   = "logging-api"
    container_port   = "8080"
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.logging_api[0].arn
    container_name   = "logging-api"
    container_port   = "8080"
  }

  lifecycle {
    ignore_changes = [desired_count]
  }
}

resource "aws_alb_target_group" "logging_api_tg" {
  count       = var.logging_enabled
  depends_on  = [aws_lb.api_alb]
  name        = "logging-api-${var.env_name}"
  port        = "8080"
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  tags = {
    Name = "logging-api-tg-${var.env_name}"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 4
    interval            = 10
    path                = "/healthcheck"
  }
}

resource "aws_alb_listener_rule" "logging_api_lr" {
  count        = var.logging_enabled
  depends_on   = [aws_alb_target_group.logging_api_tg]
  listener_arn = aws_alb_listener.alb_listener.arn
  priority     = 3

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.logging_api_tg[0].id
  }

  condition {
    path_pattern {
      values = ["/logging/*"]
    }
  }
}

resource "aws_iam_role" "logging_api_task_role" {
  count = var.logging_enabled
  name  = "${var.env_name}-logging-api-task-role"

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

resource "aws_iam_role_policy" "logging_allow_ssm" {
  count = var.logging_enabled

  name   = "${var.aws_region_name}-allow-ssm-${var.env_name}"
  role   = aws_iam_role.logging_api_task_role[0].id
  policy = data.aws_iam_policy_document.allow_ssm.json
}

resource "aws_iam_role_policy" "logging_api_task_policy" {
  count      = var.logging_enabled
  name       = "${var.env_name}-logging-api-task-policy"
  role       = aws_iam_role.logging_api_task_role[0].id
  depends_on = [aws_iam_role.logging_api_task_role]

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject"
      ],
      "Resource": "arn:aws:s3:::${var.admin_app_data_s3_bucket_name}/*"
    },
    {
      "Effect": "Allow",
      "Action":[
        "s3:GetObject",
        "s3:ListBucket",
        "s3:PutObject"
      ],
      "Resource": [
        "arn:aws:s3:::${var.metrics_bucket_name}",
        "arn:aws:s3:::${var.metrics_bucket_name}/*",
        "arn:aws:s3:::${var.export_data_bucket_name}",
        "arn:aws:s3:::${var.export_data_bucket_name}/*"
      ]
    }
  ]
}
EOF

}

resource "aws_lb" "logging_api" {
  count = var.logging_enabled

  name     = "logging-api"
  internal = true

  subnets = var.subnet_ids

  security_groups = [
    aws_security_group.logging_api_alb.id,
  ]

  load_balancer_type = "application"
}

resource "aws_alb_target_group" "logging_api" {
  count = var.logging_enabled

  name        = "logging-api"
  port        = "8080"
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 4
    interval            = 10
    path                = "/healthcheck"
  }
}

resource "aws_alb_listener" "logging_api" {
  count = var.logging_enabled

  load_balancer_arn = aws_lb.logging_api[0].arn
  protocol          = "HTTP"
  port              = 80

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.logging_api[0].id
  }
}
