resource "aws_security_group" "api_in" {
  name        = "api-in"
  description = "Allow Inbound Traffic To API"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${title(var.env_name)} API Traffic In"
  }

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.api_alb_out.id]
  }
}

resource "aws_security_group" "api_out" {
  name        = "api-out"
  description = "Allow Outbound Traffic From the API"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${title(var.env_name)} API Traffic Out"
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "lambda_user_api_out" {
  count       = var.user_signup_enabled
  name        = "lambda-user-api-out"
  description = "Allow Outbound Traffic From Lambda To User API via the internet"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${title(var.env_name)} User API Lambda Traffic Out"
  }

  egress {
    to_port     = 8443
    from_port   = 8443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow traffic out over internet so we can send messages to the user-sign-up api"
  }
}

resource "aws_security_group" "authentication_api_service" {
  name        = "authentication-api-service"
  description = "Authentication API service"
  vpc_id      = var.vpc_id

  # Ingress rule defined below to avoid a cycle.
}

resource "aws_security_group_rule" "authentication_api_service_ingress" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.authentication_api_alb.id

  security_group_id = aws_security_group.authentication_api_service.id
}

resource "aws_security_group" "logging_api_service" {
  name        = "logging-api-service"
  description = "Logging API service"
  vpc_id      = var.vpc_id

  # Ingress rule defined below to avoid a cycle.
}

resource "aws_security_group_rule" "logging_api_service_ingress" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.logging_api_alb.id

  security_group_id = aws_security_group.logging_api_service.id
}

resource "aws_security_group" "authentication_api_alb" {
  name        = "authentication_api_alb"
  description = "Security group associated with the authentication API ALB"
  vpc_id      = var.vpc_id

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"

    security_groups = var.alb_permitted_security_groups
  }

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"

    cidr_blocks = var.alb_permitted_cidr_blocks
  }

  egress {
    from_port = 8080
    to_port   = 8080
    protocol  = "tcp"

    security_groups = [
      aws_security_group.authentication_api_service.id
    ]
  }
}

resource "aws_security_group" "logging_api_alb" {
  name        = "logging_api_alb"
  description = "Security group associated with the logging API ALB"
  vpc_id      = var.vpc_id

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"

    security_groups = var.alb_permitted_security_groups
  }

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"

    cidr_blocks = var.alb_permitted_cidr_blocks
  }

  egress {
    from_port = 8080
    to_port   = 8080
    protocol  = "tcp"

    security_groups = [
      aws_security_group.logging_api_service.id
    ]
  }
}

resource "aws_security_group_rule" "permit_logging_api_ingress_to_vpc_endpoints" {
  security_group_id = var.vpc_endpoints_security_group_id

  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  description              = "Logging API"
  source_security_group_id = aws_security_group.logging_api_service.id
}

resource "aws_security_group_rule" "permit_authentication_ingress_to_vpc_endpoints" {
  security_group_id = var.vpc_endpoints_security_group_id

  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  description              = "Authentication API"
  source_security_group_id = aws_security_group.authentication_api_service.id
}

resource "aws_security_group_rule" "permit_api_ingress_to_vpc_endpoints" {
  security_group_id = var.vpc_endpoints_security_group_id

  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  description              = "User Signup API"
  source_security_group_id = aws_security_group.api_out.id
}
