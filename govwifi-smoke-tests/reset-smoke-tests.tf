variable "function_name" {
  description = "Reset Smoke Tests Lambda function"
  type        = string
  default     = "reset-smoke-tests"
}

# Build the deployment package
resource "null_resource" "build_lambda" {
  triggers = {
    code_hash         = filebase64sha256("${path.module}/reset-smoke-tests/src/lambda_function.py")
    requirements_hash = filebase64sha256("${path.module}/reset-smoke-tests/requirements.txt")
  }

  provisioner "local-exec" {
    command = "cd ${path.module}/reset-smoke-tests && chmod +x ./build-reset-smoke-tests-lambda.sh && ./build-reset-smoke-tests-lambda.sh"
  }
}

# Create deployment package
data "archive_file" "lambda_zip" {
  depends_on = [null_resource.build_lambda]

  type        = "zip"
  source_dir  = "${path.module}/reset-smoke-tests/package"
  output_path = "${path.module}/reset-smoke-tests/lambda_deployment_package.zip"
}

# IAM role for Lambda
resource "aws_iam_role" "reset_smoke_tests_lambda_role" {
  name = "${var.function_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_invoke_reset_smoke_tests" {
  name = "Reset-Smoke-Tests-Lambda-Invoke-Policy"
  role = aws_iam_role.reset_smoke_tests_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect" : "Allow",
        "Action" : "logs:CreateLogGroup",
        "Resource" : "arn:aws:logs:eu-west-2:788375279931:*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource" : [
          "arn:aws:logs:eu-west-2:${var.aws_account_id}:log-group:/aws/lambda/reset-smoke-tests:*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:CreateNetworkInterface",
          "ec2:DeleteNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeSecurityGroups"
        ],
        "Resource" = [
          "arn:aws:ec2:eu-west-2:${var.aws_account_id}:network-interface/*",
          "arn:aws:ec2:eu-west-2:${var.aws_account_id}:subnet/*",
          "${aws_security_group.reset_smoke_tests_lambda_sg.arn}"
        ]
      },
      {
      "Action" : [
          "secretsmanager:GetSecretValue"
        ],
        "Effect" : "Allow",
        "Resource" : [
          "arn:aws:secretsmanager:eu-west-2:${var.aws_account_id}:secret:rds/admin-db/credentials*"
        ]
      }
    ]
  })
}


# Lambda function
resource "aws_lambda_function" "reset_smoke_tests_lambda" {
  filename      = data.archive_file.lambda_zip.output_path
  function_name = var.function_name
  role          = aws_iam_role.reset_smoke_tests_lambda_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.12"
  timeout       = 30

  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [aws_security_group.reset_smoke_tests_lambda_sg.id]
  }

  environment {
    variables = {
      GW_SUPER_ADMIN_USER = data.aws_secretsmanager_secret_version.gw_super_admin_user.secret_string
      GW_SUPER_ADMIN_PASS = data.aws_secretsmanager_secret_version.gw_super_admin_pass.secret_string
      GW_USER             = data.aws_secretsmanager_secret_version.gw_user.secret_string
      GW_PASS             = data.aws_secretsmanager_secret_version.gw_pass.secret_string
      ######  Move this to the Lambda and use Secrets Manager there ##############
      DB_HOST = "${data.aws_secretsmanager_secret_version.admin_db.arn}:host::"
      DB_NAME = "${data.aws_secretsmanager_secret_version.admin_db.arn}:dbname::"
      DB_PASS = "${data.aws_secretsmanager_secret_version.admin_db.arn}:password::"
      DB_USER = "${data.aws_secretsmanager_secret_version.admin_db.arn}:username::"
      #####
      # Don't put passwords in environment variables in production
      # Use AWS Secrets Manager or Parameter Store instead
    }
  }
}

# Output
output "lambda_function_arn" {
  value = aws_lambda_function.reset_smoke_tests_lambda.arn
}

resource "aws_security_group" "reset_smoke_tests_lambda_sg" {
  name_prefix = "${var.function_name}-lambda-sg"
  vpc_id      = var.backend_vpc_id
  description = "Security group for the reset-smoke-tests Lambda function"

  # Outbound rule for database access (MySQL/Aurora)
  # This allows the Lambda to talk TO the database
  egress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [var.aws_security_group_admin_db_in]
    description     = "MySQL/Aurora database access"
  }

  # By default, all ingress is denied, which is correct for a Lambda.
  # If your Lambda needs to talk to other services (e.g., S3/SecretsManager via VPC Endpoints),
  # you would add other egress rules here (e.g., for port 443).
}
