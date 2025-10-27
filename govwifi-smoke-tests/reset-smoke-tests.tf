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

# The for_each loop iterates over the list of IDs
data "aws_subnet" "lambda_subnets" {
  for_each = toset(var.private_subnet_ids)
  id       = each.key
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

# IAM policy for Lambda to allow logging and access to Secrets Manager
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
# Attach AWSLambdaVPCAccessExecutionRole managed policy to the Lambda role to grant lambda access to the VPC
resource "aws_iam_role_policy_attachment" "reset_smoke_tests_vpc_access" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
  role = aws_iam_role.reset_smoke_tests_lambda_role.name
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
      ADMIN_DB_SM_PATH    = "rds/admin-db/credentials"
    }
  }
}

# Output
output "lambda_function_arn" {
  value = aws_lambda_function.reset_smoke_tests_lambda.arn
}

# Security Group for Lambda to access VPC Endpoints, Secrets Manger and RDS
resource "aws_security_group" "reset_smoke_tests_lambda_sg" {
  name_prefix = "${var.function_name}-lambda-sg"
  vpc_id      = var.backend_vpc_id
  description = "Security group for the reset-smoke-tests Lambda function sg rules"
  tags = {
    Name = "${var.env} Smoke Test Reset lambda Access"
  }
}

# Ingress rule to allow Lambda to initiate outbound connections from Secrets Manager VPC Endpoint
resource "aws_security_group_rule" "allow_lambda_to_secretsmanager_endpoint" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  # This is the EXISTING security group ID attached to your VPC Endpoint
  security_group_id        = var.vpc_endpoints_security_group_id

  # CRITICAL: This is the ID of the Security Group attached to your Lambda function
  source_security_group_id = aws_security_group.reset_smoke_tests_lambda_sg.id
  description              = "Allow HTTPS from Lambda to Secrets Manager VPC Endpoint"
}

# Egress rule to allow Lambda to initiate outbound connections to Secrets Manager VPC Endpoint
resource "aws_security_group_rule" "lambda_to_secretsmanager_egress" {
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  # The security_group_id refers to the group getting the rule (your Lambda's SG)
  security_group_id        = aws_security_group.reset_smoke_tests_lambda_sg.id

  # The "destination" source_security_group_id refers to the TARGET (the Endpoint's SG)
  source_security_group_id = var.vpc_endpoints_security_group_id

  description              = "Allow outbound HTTPS from Lambda to Secrets Manager VPC Endpoint"
}

# Ingress rule to allow Lambda to connect to the RDS database
resource "aws_security_group_rule" "allow_lambda_to_database_endpoint" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  # This is the EXISTING security group ID attached to the admin db
  security_group_id        = var.aws_security_group_admin_db_in

  # CRITICAL: This is the ID of the Security Group attached to the Lambda function
  source_security_group_id = aws_security_group.reset_smoke_tests_lambda_sg.id
  description              = "Allow HTTPS from Lambda to RDS security group"
}

# Egress rule to allow Lambda to connect to the RDS database
resource "aws_security_group_rule" "lambda_to_database_egress" {
  type                     = "egress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  # The security_group_id refers to the group getting the rule (the Lambda's SG)
  security_group_id        = aws_security_group.reset_smoke_tests_lambda_sg.id

  # The "destination" source_security_group_id refers to the TARGET (the admin db's SG)
  source_security_group_id = var.aws_security_group_admin_db_in

  description              = "Allow outbound HTTPS from Lambda to RDS security group"
}