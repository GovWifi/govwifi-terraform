resource "aws_security_group" "admin_alb_in" {
  name        = "admin-alb-in"
  description = "Allow Inbound Traffic to the admin platform ALB"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${title(var.env_name)} Admin ALB Traffic In"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "admin_alb_out" {
  name        = "admin-alb-out"
  description = "Allow Outbound Traffic from the admin platform ALB"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${title(var.env_name)} Admin ALB Traffic Out"
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "admin_ec2_in" {
  name        = "admin-ec2-in"
  description = "Allow Inbound Traffic To Admin from the ALB"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${title(var.env_name)} Admin EC2 Traffic In"
  }

  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.admin_alb_out.id]
  }
}

resource "aws_security_group" "admin_ec2_out" {
  name        = "api-ec2-out"
  description = "Allow Outbound Traffic From the Admin EC2 container"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${title(var.env_name)} Admin EC2 Traffic Out"
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "admin_db_in" {
  name        = "admin-db-in"
  description = "Allow connections to the DB"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${title(var.env_name)} Admin DB in"
  }

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = distinct(data.aws_subnet.backend_subnet.*.cidr_block)
  }
}

data "aws_subnet" "backend_subnet" {
  count = length(var.subnet_ids)
  id    = var.subnet_ids[count.index]
}

resource "aws_security_group_rule" "permit_admin_app_ingress_to_vpc_endpoints" {
  security_group_id = var.vpc_endpoints_security_group_id

  type      = "ingress"
  from_port = 443
  to_port   = 443
  protocol  = "tcp"

  source_security_group_id = aws_security_group.admin_ec2_out.id
}
