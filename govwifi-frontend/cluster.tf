# Create ECS Cluster

resource "aws_ecs_cluster" "frontend_fargate" {
  name = "frontend-fargate"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_cluster_capacity_providers" "frontend_fargate" {
  cluster_name = aws_ecs_cluster.frontend_fargate.name

  capacity_providers = ["FARGATE"]
}

resource "aws_cloudwatch_log_group" "frontend_log_group" {
  name = "${var.env_name}-frontend-docker-log-group"

  retention_in_days = var.log_retention
}

resource "aws_cloudwatch_log_group" "frontend" {
  name = "frontend"

  retention_in_days = var.log_retention
}

data "aws_caller_identity" "current" {}

resource "aws_ecr_replication_configuration" "main" {
  count = var.create_ecr

  replication_configuration {
    rule {
      destination {
        region      = "eu-west-1"
        registry_id = data.aws_caller_identity.current.account_id
      }

      repository_filter {
        filter_type = "PREFIX_MATCH"
        filter      = "govwifi/frontend"
      }

      repository_filter {
        filter_type = "PREFIX_MATCH"
        filter      = "govwifi/raddb"
      }
    }
  }
}

resource "aws_ecs_task_definition" "radius_task" {
  family             = "radius-task-${var.env_name}"
  task_role_arn      = aws_iam_role.ecs_task_role.arn
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn

  volume {
    name = "raddb-certs"
  }

  container_definitions = <<EOF
[
  {
    "memory": 1500,
    "portMappings": [
      {
        "hostPort": 8080,
        "containerPort": 80,
        "protocol": "tcp"
      },
      {
        "hostPort": 3000,
        "containerPort": 3000,
        "protocol": "tcp"
      },
      {
        "hostPort": 1812,
        "containerPort": 1812,
        "protocol": "udp"
      },
      {
        "hostPort": 1813,
        "containerPort": 1813,
        "protocol": "udp"
      },
      {
        "hostPort": 9812,
        "containerPort": 9812,
        "protocol": "tcp"
      }
    ],
    "essential": true,
    "mountPoints": [
      {
        "sourceVolume": "raddb-certs",
        "containerPath": "/etc/raddb/certs"
      }
    ],
    "name": "frontend-radius",
    "environment": [
      {
        "name": "AUTHORISATION_API_BASE_URL",
        "value": "${var.auth_api_base_url}"
      },{
        "name": "LOGGING_API_BASE_URL",
        "value": "${var.logging_api_base_url}"
      },{
        "name": "RADIUSD_PARAMS",
        "value": "${var.radiusd_params}"
      },{
        "name": "RACK_ENV",
        "value": "${var.rack_env}"
      },{
        "name": "SERVICE_DOMAIN",
        "value": "${var.env_subdomain}"
      },{
        "name": "SENTRY_CURRENT_ENV",
        "value": "${var.sentry_current_env}"
      }
    ],
    "secrets": [
      {
        "name": "BACKEND_API_KEY",
        "valueFrom": "${data.aws_secretsmanager_secret_version.shared_key.arn}:shared-key::"
      },{
        "name": "HEALTH_CHECK_IDENTITY",
        "valueFrom": "${data.aws_secretsmanager_secret_version.healthcheck.arn}:identity::"
      },{
        "name": "HEALTH_CHECK_PASSWORD",
        "valueFrom": "${data.aws_secretsmanager_secret_version.healthcheck.arn}:pass::"
      },{
        "name": "HEALTH_CHECK_RADIUS_KEY",
        "valueFrom": "${data.aws_secretsmanager_secret_version.healthcheck.arn}:key::"
      },{
        "name": "HEALTH_CHECK_SSID",
        "valueFrom": "${data.aws_secretsmanager_secret_version.healthcheck.arn}:ssid::"
      }
    ],
    "image": "${local.frontend_image_new}",
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${aws_cloudwatch_log_group.frontend_log_group.name}",
        "awslogs-region": "${var.aws_region}",
        "awslogs-stream-prefix": "${var.env_name}-docker-logs"
      }
    },
    "cpu": 1000,
    "expanded": true,
    "dependsOn": [
      {
        "containerName": "populate-radius-certs",
        "condition": "SUCCESS"
      }
    ]
  },
  {
    "essential": false,
    "mountPoints": [
      {
        "sourceVolume": "raddb-certs",
        "containerPath": "/etc/raddb/certs"
      }
    ],
    "name": "populate-radius-certs",
    "environment": [
      {
        "name": "ALLOWLIST_BUCKET",
        "value": "s3://${var.admin_app_data_s3_bucket_name}"
      },{
        "name": "CERT_STORE_BUCKET",
        "value": "s3://${aws_s3_bucket.frontend_cert_bucket.bucket}"
      }
    ],
    "image": "${local.raddb_image_new}",
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${aws_cloudwatch_log_group.frontend_log_group.name}",
        "awslogs-region": "${var.aws_region}",
        "awslogs-stream-prefix": "${var.env_name}-docker-logs"
      }
    },
    "memory": 1500,
    "cpu": 1000,
    "expanded": true
  }
]
EOF

}

resource "aws_ecs_task_definition" "frontend_fargate" {
  family             = "frontend-fargate"
  task_role_arn      = aws_iam_role.ecs_task_role.arn
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn

  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 1024
  memory                   = 2048

  volume {
    name = "raddb-certs"
  }

  container_definitions = <<EOF
[
  {
    "portMappings": [
      {
        "hostPort": 3000,
        "containerPort": 3000,
        "protocol": "tcp"
      },
      {
        "hostPort": 1812,
        "containerPort": 1812,
        "protocol": "udp"
      },
      {
        "hostPort": 1813,
        "containerPort": 1813,
        "protocol": "udp"
      },
      {
        "hostPort": 9812,
        "containerPort": 9812,
        "protocol": "tcp"
      }
    ],
    "essential": true,
    "mountPoints": [
      {
        "sourceVolume": "raddb-certs",
        "containerPath": "/etc/raddb/certs"
      }
    ],
    "name": "frontend-radius",
    "environment": [
      {
        "name": "AUTHORISATION_API_BASE_URL",
        "value": "http://${var.authentication_api_internal_dns_name}"
      },{
        "name": "LOGGING_API_BASE_URL",
        "value": "http://${var.logging_api_internal_dns_name}"
      },{
        "name": "RADIUSD_PARAMS",
        "value": "${var.radiusd_params}"
      },{
        "name": "RACK_ENV",
        "value": "${var.rack_env}"
      },{
        "name": "SERVICE_DOMAIN",
        "value": "${var.env_subdomain}"
      },{
        "name": "SENTRY_CURRENT_ENV",
        "value": "${var.sentry_current_env}"
      }
    ],
    "secrets": [
      {
        "name": "BACKEND_API_KEY",
        "valueFrom": "${data.aws_secretsmanager_secret_version.shared_key.arn}:shared-key::"
      },{
        "name": "HEALTH_CHECK_IDENTITY",
        "valueFrom": "${data.aws_secretsmanager_secret_version.healthcheck.arn}:identity::"
      },{
        "name": "HEALTH_CHECK_PASSWORD",
        "valueFrom": "${data.aws_secretsmanager_secret_version.healthcheck.arn}:pass::"
      },{
        "name": "HEALTH_CHECK_RADIUS_KEY",
        "valueFrom": "${data.aws_secretsmanager_secret_version.healthcheck.arn}:key::"
      },{
        "name": "HEALTH_CHECK_SSID",
        "valueFrom": "${data.aws_secretsmanager_secret_version.healthcheck.arn}:ssid::"
      }
    ],
    "image": "${local.frontend_image_new}",
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${aws_cloudwatch_log_group.frontend.name}",
        "awslogs-region": "${var.aws_region}",
        "awslogs-stream-prefix": "frontend"
      }
    },
    "expanded": true,
    "dependsOn": [
      {
        "containerName": "populate-radius-certs",
        "condition": "SUCCESS"
      }
    ]
  },
  {
    "essential": false,
    "mountPoints": [
      {
        "sourceVolume": "raddb-certs",
        "containerPath": "/etc/raddb/certs"
      }
    ],
    "name": "populate-radius-certs",
    "environment": [
      {
        "name": "ALLOWLIST_BUCKET",
        "value": "s3://${var.admin_app_data_s3_bucket_name}"
      },{
        "name": "CERT_STORE_BUCKET",
        "value": "s3://${aws_s3_bucket.frontend_cert_bucket.bucket}"
      },{
        "name": "AWS_REGION",
        "value": "${var.aws_region}"
      },{
        "name": "TRUSTED_CERTIFICATES_KEY",
        "value": "${var.trusted_certificates_key}"
      }
    ],
    "image": "${local.raddb_image_new}",
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${aws_cloudwatch_log_group.frontend.name}",
        "awslogs-region": "${var.aws_region}",
        "awslogs-stream-prefix": "frontend"
      }
    },
    "expanded": true
  }
]
EOF
}

resource "aws_ecs_service" "load_balanced_frontend_service" {
  name            = "load-balanced-frontend"
  cluster         = aws_ecs_cluster.frontend_fargate.id
  launch_type     = "FARGATE"
  task_definition = aws_ecs_task_definition.frontend_fargate.arn
  desired_count   = var.radius_task_count

  enable_execute_command = true

  load_balancer {
    target_group_arn = aws_lb_target_group.main.arn
    container_name   = "frontend-radius"
    container_port   = 1812
  }

  network_configuration {
    subnets = [for subnet in aws_subnet.wifi_frontend_subnet : subnet.id]

    security_groups = [
      aws_security_group.load_balanced_frontend_service.id,
    ]
  }

  service_registries {
    registry_arn = aws_service_discovery_service.main.arn
    port         = 9812
  }
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id            = aws_vpc.wifi_frontend.id
  service_name      = "com.amazonaws.${var.aws_region}.ecr.dkr"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.vpc_endpoints.id,
  ]

  subnet_ids = [for subnet in aws_subnet.wifi_frontend_subnet : subnet.id]

  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id            = aws_vpc.wifi_frontend.id
  service_name      = "com.amazonaws.${var.aws_region}.ecr.api"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.vpc_endpoints.id,
  ]

  subnet_ids = [for subnet in aws_subnet.wifi_frontend_subnet : subnet.id]

  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.wifi_frontend.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [aws_vpc.wifi_frontend.main_route_table_id]
}

resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id            = aws_vpc.wifi_frontend.id
  service_name      = "com.amazonaws.${var.aws_region}.secretsmanager"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.vpc_endpoints.id,
  ]

  subnet_ids = [for subnet in aws_subnet.wifi_frontend_subnet : subnet.id]

  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "logs" {
  vpc_id            = aws_vpc.wifi_frontend.id
  service_name      = "com.amazonaws.${var.aws_region}.logs"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.vpc_endpoints.id,
  ]

  subnet_ids = [for subnet in aws_subnet.wifi_frontend_subnet : subnet.id]

  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ssm" {
  vpc_id            = aws_vpc.wifi_frontend.id
  service_name      = "com.amazonaws.${var.aws_region}.ssm"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.vpc_endpoints.id,
  ]

  subnet_ids = [for subnet in aws_subnet.wifi_frontend_subnet : subnet.id]

  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id            = aws_vpc.wifi_frontend.id
  service_name      = "com.amazonaws.${var.aws_region}.ssmmessages"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.vpc_endpoints.id,
  ]

  subnet_ids = [for subnet in aws_subnet.wifi_frontend_subnet : subnet.id]

  private_dns_enabled = true
}

resource "aws_service_discovery_private_dns_namespace" "main" {
  name        = "frontend.internal"
  description = "Frontend namespace"
  vpc         = aws_vpc.wifi_frontend.id
}

resource "aws_service_discovery_service" "main" {
  name = "metrics"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.main.id

    dns_records {
      ttl  = 15
      type = "SRV"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 10
  }
}
