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

resource "aws_iam_role_policy" "metrics_api_task_execution_policy" {
  name = "metrics-api-task-execution-policy-${var.env}-${var.region_name}"
  role = aws_iam_role.metrics_api_task_execution_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue",
        "kms:Decrypt"
      ],
      "Resource": [
        "${data.aws_secretsmanager_secret.metrics_api_key.arn}",
        "${data.aws_secretsmanager_secret.metrics_data_publisher_tableau.arn}"
      ]
    }
  ]
}
EOF
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

  # Resources are wildcards to allow any ecs-execute-command session to connect from the container
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
        "ssmmessages:OpenDataChannel",
        "secretsmanager:GetSecretValue",
        "kms:Decrypt"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role" "metrics_events_role" {
  name = "metrics-events-role-${var.env}-${var.region_name}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "events.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "metrics_events_policy" {
  name = "metrics-events-policy-${var.env}-${var.region_name}"
  role = aws_iam_role.metrics_events_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecs:RunTask"
      ],
      "Resource": [
        "${aws_ecs_task_definition.metrics_data_publisher.arn}"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "iam:PassRole"
      ],
      "Resource": [
        "${aws_iam_role.metrics_api_task_execution_role.arn}",
        "${aws_iam_role.metrics_api_task_role.arn}"
      ]
    }
  ]
}
EOF
}
