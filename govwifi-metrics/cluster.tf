resource "aws_ecs_cluster" "metrics_cluster" {
  name = "metrics-cluster-${var.env}"

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "metrics_log_group" {
  name = "metrics-api-log-group-${var.env}"

  retention_in_days = var.log_retention

  tags = var.tags
}

resource "aws_ecs_task_definition" "metrics_api" {
  family                   = "metrics-api-task-${var.env}"
  requires_compatibilities = ["FARGATE"]
  task_role_arn            = aws_iam_role.metrics_api_task_role.arn
  execution_role_arn       = aws_iam_role.metrics_api_task_execution_role.arn
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"

  container_definitions = <<EOF
[
    {
      "name": "metrics-api",
      "image": "${var.metrics_api_docker_image}",
      "portMappings": [
        {
          "containerPort": 8080,
          "protocol": "tcp"
        }
      ],
      "essential": true,
      "environment": [
        {
          "name": "DATABASE_DSN",
          "value": "${local.database_dsn}"
        },
        {
          "name": "PERMITTED_HOSTS",
          "value": "metrics.${var.env_subdomain}.service.gov.uk"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "${aws_cloudwatch_log_group.metrics_log_group.name}",
          "awslogs-region": "${var.aws_region}",
          "awslogs-stream-prefix": "metrics-api"
        }
      }
    }
]
EOF

  tags = var.tags
}

resource "aws_ecs_service" "metrics_service" {
  name             = "metrics-api-service-${var.env}"
  cluster          = aws_ecs_cluster.metrics_cluster.id
  task_definition  = aws_ecs_task_definition.metrics_api.arn
  desired_count    = 1
  launch_type      = "FARGATE"
  platform_version = "1.4.0"

  enable_execute_command = true

  load_balancer {
    target_group_arn = aws_alb_target_group.metrics_tg.arn
    container_name   = "metrics-api"
    container_port   = "8080"
  }

  network_configuration {
    subnets = var.backend_subnet_ids

    security_groups = [
      aws_security_group.metrics_service_in.id,
      aws_security_group.metrics_service_out.id,
    ]

    assign_public_ip = true
  }

  lifecycle {
    ignore_changes = [desired_count]
  }

  tags = var.tags
}

resource "aws_alb_target_group" "metrics_tg" {
  name        = "metrics-api-tg-${var.env}"
  port        = "8080"
  protocol    = "HTTP"
  vpc_id      = var.backend_vpc_id
  target_type = "ip"

  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = "/health"
  }

  tags = var.tags
}
