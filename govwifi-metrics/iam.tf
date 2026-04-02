resource "aws_iam_role" "metrics_api_task_execution_role" {
  name = "metrics-api-ecsTaskExecutionRole-${var.env}-${var.region_name}"

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

resource "aws_iam_role_policy_attachment" "metrics_api_task_execution_role_policy" {
  role       = aws_iam_role.metrics_api_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "metrics_api_task_role" {
  name = "metrics-api-task-role-${var.env}-${var.region_name}"

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

resource "aws_iam_role_policy" "metrics_api_task_policy" {
  name = "metrics-api-task-policy-${var.env}-${var.region_name}"
  role = aws_iam_role.metrics_api_task_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ssmmessages:CreateControlChannel",
        "ssmmessages:CreateDataChannel",
        "ssmmessages:OpenControlChannel",
        "ssmmessages:OpenDataChannel"
      ],
      # Resources are wildcards to allow any ecs-execute-command session to connect from the container.
      "Resource": "*"
    }
  ]
}
EOF
}
