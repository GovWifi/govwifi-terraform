/*
	ECS service for govwifi-capacity-testing.
	- Fargate ECS cluster and service (desired_count = 1)
	- Task definition uses the ECR repo created in ecr.tf
	- CloudWatch Logs group
	- Execution role with AmazonECSTaskExecutionRolePolicy and SSM messaging permissions for ECS Exec
	- Service has `enable_execute_command = true` so you can use AWS SSM to exec into the container
*/

resource "aws_cloudwatch_log_group" "capacity_testing" {
	name              = "/ecs/govwifi-capacity-testing-${var.env}"
	retention_in_days = 30
	tags = { Env = var.env }
}

resource "aws_ecs_cluster" "capacity" {
	name = "govwifi-capacity-${var.env}"
	setting {
		name  = "containerInsights"
		value = "disabled"
	}
	tags = { Env = var.env }
}

resource "aws_ecs_task_definition" "capacity_testing" {
	family                   = "govwifi-capacity-testing-${var.env}"
	requires_compatibilities = ["FARGATE"]
	network_mode             = "awsvpc"
	cpu                      = "8192"
	memory                   = "61440"
	execution_role_arn       = aws_iam_role.ecs_task_execution.arn
	task_role_arn            = aws_iam_role.ecs_task_role.arn

	container_definitions = <<EOF
[
		{
			"name": "capacity-testing",
			"image": "${aws_ecr_repository.capacity_testing.repository_url}:latest",
			"essential": true,
			"secrets": [
				{
				"name": "RADIUS_SERVER_IP",
				"valueFrom": "arn:aws:ssm:eu-west-2:${var.aws_account_id}:parameter/govwifi/capacity_testing/radius_server_ip"
				},
				{
				"name": "RADIUS_SECRET",
				"valueFrom": "arn:aws:ssm:eu-west-2:${var.aws_account_id}:parameter/govwifi/capacity_testing/radius_secret"
				},
				{
				"name": "GW_USERNAME",
				"valueFrom": "arn:aws:ssm:eu-west-2:${var.aws_account_id}:parameter/govwifi/capacity_testing/gw_username"
				},
				{
				"name": "GW_PASSWORD",
				"valueFrom": "arn:aws:ssm:eu-west-2:${var.aws_account_id}:parameter/govwifi/capacity_testing/gw_password"
				}
			],
			"logConfiguration": {
				"logDriver": "awslogs",
				"options": {
					"awslogs-group": "${aws_cloudwatch_log_group.capacity_testing.name}",
					"awslogs-region": "${var.aws_region}",
					"awslogs-stream-prefix": "capacity-testing"
				}
			}
		}
	]
EOF
}

resource "aws_ecs_service" "capacity_testing" {
	name            = "govwifi-capacity-testing-svc-${var.env}"
	cluster         = aws_ecs_cluster.capacity.id
	task_definition = aws_ecs_task_definition.capacity_testing.arn
	desired_count   = 3
	launch_type     = "FARGATE"
	platform_version = "LATEST"

	network_configuration {
		subnets         = aws_subnet.capacity_private[*].id
		security_groups = [aws_security_group.capacity_tasks_sg.id]
		assign_public_ip = false
	}

	enable_execute_command = true

	tags = { Env = var.env }
}


resource "aws_security_group" "capacity_tasks_sg" {
	name        = "govwifi-capacity-tasks-sg-${var.env}"
	description = "Security group for capacity testing ECS tasks"
	vpc_id      = aws_vpc.capacity_public.id

	tags = {
		Name = "${title(var.env)} Capacity Testing"
	}

  ingress {
    description = "RADIUS traffic"
    from_port   = 1812
    to_port     = 1812
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    cidr_blocks  	= ["0.0.0.0/0"]
  }

  ingress {
    description = "Need for Jmeter workers. Allow traffic from self"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  egress {
    description = "Allow all traffic out"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


}




