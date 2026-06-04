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
        "${data.aws_secretsmanager_secret.metrics_api_key.arn}"
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

resource "aws_iam_policy" "metrics_codebuild_vpc_policy" {
  name = "GovwifiMetricsCodeBuildVPC-${var.env}"
  path = "/"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateNetworkInterface",
        "ec2:DescribeDhcpOptions",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DeleteNetworkInterface",
        "ec2:DescribeSubnets",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeVpcs"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateNetworkInterfacePermission"
      ],
      "Resource": "arn:aws:ec2:${var.aws_region}:${var.aws_account_id}:network-interface/*",
      "Condition": {
        "StringEquals": {
          "ec2:AuthorizedService": "codebuild.amazonaws.com"
        },
        "ArnEquals": {
          "ec2:Subnet": [
            ${join(",\n            ", [for subnet_id in var.backend_private_subnet_ids : "\"arn:aws:ec2:${var.aws_region}:${var.aws_account_id}:subnet/${subnet_id}\""])}
          ]
        }
      }
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "metrics_codebuild_vpc" {
  role       = var.govwifi_codebuild_role_name
  policy_arn = aws_iam_policy.metrics_codebuild_vpc_policy.arn
}

resource "aws_iam_policy" "metrics_codebuild_s3_policy" {
  name = "GovwifiMetricsCodeBuildS3-${var.env}"
  path = "/"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:GetBucketAcl",
        "s3:GetBucketLocation",
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:PutObject"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_s3_bucket.tableau_publication_bucket.arn}",
        "${aws_s3_bucket.tableau_publication_bucket.arn}/*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "metrics_codebuild_s3" {
  role       = var.govwifi_codebuild_role_name
  policy_arn = aws_iam_policy.metrics_codebuild_s3_policy.arn
}
