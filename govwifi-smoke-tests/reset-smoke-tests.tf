variable "function_name" {
  description = "Reset Smoke Tests Lambda function"
  type        = string
  default     = "reset-smoke-tests"
}

# Build the deployment package
resource "null_resource" "build_lambda" {
  triggers = {
    code_hash = filebase64sha256("${path.module}/reset-smoke-tests/src/lambda_function.py")
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
            "Effect": "Allow",
            "Action": "logs:CreateLogGroup",
            "Resource": "arn:aws:logs:eu-west-2:788375279931:*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": [
                "arn:aws:logs:eu-west-2:${var.aws_account_id}:log-group:/aws/lambda/reset-smoke-tests:*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:CreateNetworkInterface",
                "ec2:DeleteNetworkInterface",
                "ec2:DescribeNetworkInterfaces"
            ],
            "Resource" = [
                "arn:aws:ec2:eu-west-2:${var.aws_account_id}:network-interface/*",
                "arn:aws:ec2:eu-west-2:${var.aws_account_id}:subnet/*",
                "arn:aws:ec2:eu-west-2:${var.aws_account_id}:security-group/database_allow_reset_smoke_tests_lambda"
            ]
        },
        {
            "Action": [
                "secretsmanager:GetSecretValue"
            ],
            "Effect": "Allow",
            "Resource": [
                "arn:aws:secretsmanager:eu-west-2:${var.aws_account_id}:secret:rds/admin-db/credentials*"
            ]
        }
    ]
  })
}

# Attach basic execution policy
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role = aws_iam_role.reset_smoke_tests_lambda_role.id
}

# Lambda function
resource "aws_lambda_function" "mysql_lambda" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = var.function_name
  role             = aws_iam_role.reset_smoke_tests_lambda_role.id
  handler         = "lambda_function.lambda_handler"
  runtime         = "python3.12"
  timeout         = 30

  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      GW_SUPER_ADMIN_USER = data.aws_secretsmanager_secret_version.gw_super_admin_user.secret_string
      GW_SUPER_ADMIN_PASS = data.aws_secretsmanager_secret_version.gw_super_admin_pass.secret_string
      GW_USER = data.aws_secretsmanager_secret_version.gw_user.secret_string
      GW_PASS = data.aws_secretsmanager_secret_version.gw_pass.secret_string
######  Move this to the Lambda and use Secrets Manager there ##############
      DB_HOST = "${data.aws_secretsmanager_secret_version.admin_db.arn}:host::"
      DB_NAME = "${data.aws_secretsmanager_secret_version.admin_db.arn}:dbname::"
      DB_PASS = "${data.aws_secretsmanager_secret_version.admin_db.arn}:password::"
      DB_USER =  "${data.aws_secretsmanager_secret_version.admin_db.arn}:username::"
#####
      # Don't put passwords in environment variables in production
      # Use AWS Secrets Manager or Parameter Store instead
    }
  }
}

# Output
output "lambda_function_arn" {
  value = aws_lambda_function.mysql_lambda.arn
}

resource "aws_security_group" "database_allow_reset_smoke_tests_lambda_sg" {
  name_prefix = "${var.function_name}-lambda-sg"
  vpc_id      = var.vpc_id

  # Outbound rule for database access (MySQL/Aurora)
  egress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [var.vpc_endpoints_security_group_id]
    description     = "MySQL/Aurora database access"
  }
}

# Update database security group to allow Lambda access
resource "aws_security_group_rule" "database_allow_reset_smoke_tests_lambda" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.database_allow_reset_smoke_tests_lambda_sg.id
  security_group_id        = var.vpc_endpoints_security_group_id
  description              = "Allow Lambda function access to database"
}
