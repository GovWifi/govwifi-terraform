resource "aws_cloudwatch_log_group" "authentication_api_log_group" {
  name = "${var.env_name}-authentication-api-docker-log-group"

  retention_in_days = var.log_retention
}


resource "aws_ecs_task_definition" "authentication_api_task" {
  family                   = "authentication-api-task-${var.env_name}"
  requires_compatibilities = ["FARGATE"]
  task_role_arn            = aws_iam_role.authentication_api_ecs_task.arn
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  memory                   = 512
  cpu                      = "256"
  network_mode             = "awsvpc"

  container_definitions = <<EOF
[
    {
      "volumesFrom": [],
      "memory": 512,
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
      "name": "authentication-api",
      "ulimits": null,
      "dockerSecurityOptions": null,
      "environment": [
        {
          "name": "DB_NAME",
          "value": "govwifi_${var.env}_users"
        },{
          "name": "DB_HOSTNAME",
          "value": "${var.user_rr_hostname}"
        },{
          "name": "RACK_ENV",
          "value": "${var.rack_env}"
        },{
          "name": "SENTRY_CURRENT_ENV",
          "value": "${var.sentry_current_env}"
        },{
          "name": "ENVIRONMENT_NAME",
          "value": "${var.env_name}"
        }
      ],"secrets": [
        {
          "name": "DB_PASS",
          "valueFrom": "${data.aws_secretsmanager_secret_version.users_db.arn}:password::"
        },{
          "name": "DB_USER",
          "valueFrom": "${data.aws_secretsmanager_secret_version.users_db.arn}:username::"
        },{
          "name": "SENTRY_DSN",
          "valueFrom": "${data.aws_secretsmanager_secret.authentication_api_sentry_dsn.arn}"
        }
      ],
      "links": null,
      "workingDirectory": null,
      "readonlyRootFilesystem": null,
      "image": "${local.tools_account_id}.dkr.ecr.eu-west-2.amazonaws.com/govwifi/authentication-api/${var.env}:latest",

      "command": null,
      "user": null,
      "dockerLabels": null,
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "${aws_cloudwatch_log_group.authentication_api_log_group.name}",
          "awslogs-region": "${var.aws_region}",
          "awslogs-stream-prefix": "${var.env_name}-authentication-api-docker-logs"
        }
      },
      "cpu": 0,
      "privileged": null,
      "expanded": true
    }
]
EOF

}

resource "aws_ecs_service" "authentication_api_service" {
  name             = "authentication-api-service-${var.env_name}"
  cluster          = aws_ecs_cluster.api_cluster.id
  task_definition  = aws_ecs_task_definition.authentication_api_task.arn
  desired_count    = var.authentication_api_count
  launch_type      = "FARGATE"
  platform_version = "1.4.0"

  enable_execute_command = true

  health_check_grace_period_seconds = 20

  network_configuration {
    security_groups = concat(
      [aws_security_group.api_in.id],
      [aws_security_group.api_out.id],
      [aws_security_group.authentication_api_service.id]
    )

    subnets          = var.subnet_ids
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.alb_target_group.arn
    container_name   = "authentication-api"
    container_port   = "8080"
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.authentication_api.arn
    container_name   = "authentication-api"
    container_port   = "8080"
  }

  lifecycle {
    ignore_changes = [desired_count]
  }

}

resource "aws_alb_listener_rule" "static" {
  depends_on   = [aws_alb_target_group.alb_target_group]
  listener_arn = aws_alb_listener.alb_listener.arn
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.alb_target_group.id
  }

  condition {
    path_pattern {
      values = ["/authorize/*"]
    }
  }
}

resource "aws_alb_target_group" "alb_target_group" {
  depends_on  = [aws_lb.api_alb]
  name        = "api-lb-tg-${var.env_name}"
  port        = "8080"
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  tags = {
    Name = "api-alb-tg-${var.env_name}"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 4
    interval            = 10
    path                = "/authorize/user/HEALTH"
  }
}

resource "aws_lb" "authentication_api" {
  name     = "authentication-api"
  internal = true

  subnets = var.subnet_ids

  security_groups = [
    aws_security_group.authentication_api_alb.id,
  ]

  load_balancer_type = "application"
}

resource "aws_alb_target_group" "authentication_api" {
  name        = "authentication-api"
  port        = "8080"
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 4
    interval            = 10
    path                = "/authorize/user/HEALTH"
  }
}

resource "aws_alb_listener" "authentication" {
  load_balancer_arn = aws_lb.authentication_api.arn
  protocol          = "HTTP"
  port              = 80

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.authentication_api.id
  }
}

resource "aws_iam_role" "authentication_api_ecs_task" {
  name = "${var.aws_region_name}-apiEcsTask-${var.rack_env}"

  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

resource "aws_iam_role_policy" "allow_ssm" {
  name   = "${var.aws_region_name}-allow-ssm-${var.env_name}"
  role   = aws_iam_role.authentication_api_ecs_task.id
  policy = data.aws_iam_policy_document.allow_ssm.json
}
