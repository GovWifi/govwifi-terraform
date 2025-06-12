resource "aws_security_group" "be_ecs_out" {
  name        = "be-ecs-out"
  description = "Allow the ECS agent to talk to the ECS endpoints"
  vpc_id      = aws_vpc.wifi_backend.id

  tags = {
    Name = "${title(var.env_name)} Backend ECS out"
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 123
    to_port     = 123
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [for subnet in aws_subnet.wifi_backend_subnet : subnet.cidr_block]
  }

  egress {
    from_port   = 11211
    to_port     = 11211
    protocol    = "tcp"
    cidr_blocks = [for subnet in aws_subnet.wifi_backend_subnet : subnet.cidr_block]
  }
}

resource "aws_security_group" "be_db_in" {
  name        = "be-db-in"
  description = "Allow connections to the DB"
  vpc_id      = aws_vpc.wifi_backend.id

  tags = {
    Name = "${title(var.env_name)} Backend DB in"
  }

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [for subnet in aws_subnet.wifi_backend_subnet : subnet.cidr_block]
  }
}

resource "aws_security_group" "be_radius_api_in" {
  name        = "be-radius-api-in"
  description = "Allow inbound API calls from the RADIUS servers"
  vpc_id      = aws_vpc.wifi_backend.id

  tags = {
    Name = "${title(var.env_name)} Backend RADIUS API in"
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [for ip in var.frontend_radius_ips : "${ip}/32"]
  }

  ingress {
    from_port   = 8443
    to_port     = 8443
    protocol    = "tcp"
    cidr_blocks = [for ip in var.frontend_radius_ips : "${ip}/32"]
  }
}

resource "aws_security_group" "vpc_endpoints" {
  name        = "backend_vpc_endpoints"
  description = "Permit traffic to the backend VPC endpoints"
  vpc_id      = aws_vpc.wifi_backend.id

  tags = {
    Name = "${title(var.env_name)} Backend VPC Endpoints"
  }
}

resource "aws_security_group_rule" "vpc_endpoints_ingress" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Required for SSM"
  security_group_id = aws_security_group.vpc_endpoints.id
}
