resource "aws_security_group" "london_metrics_db_sg" {
  name        = "london-metrics-db"
  description = "Allow inbound traffic from metrics-api to metrics DB"
  vpc_id      = var.backend_vpc_id

  tags = merge(var.tags, {
    Name = "${var.env} Metrics DB"
  })
}

resource "aws_security_group_rule" "metrics_db_ingress" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.metrics_service_in.id
  security_group_id        = aws_security_group.london_metrics_db_sg.id
}

resource "aws_db_subnet_group" "london_metrics_db_subnet_group" {
  name       = "london-metrics-subnets-${var.env}"
  subnet_ids = var.backend_subnet_ids

  tags = merge(var.tags, {
    Name = "${var.env} Metrics Subnets"
  })
}

resource "aws_security_group" "metrics_alb_in" {
  name        = "metrics-alb-in-${var.env}"
  description = "Allow Inbound Traffic to the metrics internal ALB"
  vpc_id      = var.backend_vpc_id

  tags = merge(var.tags, {
    Name = "${var.env} Metrics ALB Traffic In"
  })

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [var.admin_sg_id, var.api_sg_id]
  }
}

resource "aws_security_group" "metrics_alb_out" {
  name        = "metrics-alb-out-${var.env}"
  description = "Allow Outbound Traffic from the metrics internal ALB"
  vpc_id      = var.backend_vpc_id

  tags = merge(var.tags, {
    Name = "${var.env} Metrics ALB Traffic Out"
  })

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.backend_vpc_cidr_block]
  }
}

resource "aws_security_group" "metrics_service_in" {
  name        = "metrics-service-in-${var.env}"
  description = "Allow Inbound Traffic To Metrics API from the internal ALB"
  vpc_id      = var.backend_vpc_id

  tags = merge(var.tags, {
    Name = "${var.env} Metrics API Traffic In"
  })

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.metrics_alb_out.id]
  }
}

resource "aws_security_group" "metrics_service_out" {
  name        = "metrics-service-out-${var.env}"
  description = "Allow Outbound Traffic From the Metrics API container"
  vpc_id      = var.backend_vpc_id

  tags = merge(var.tags, {
    Name = "${var.env} Metrics API Traffic Out"
  })

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.backend_vpc_cidr_block]
  }
}

resource "aws_security_group_rule" "permit_metrics_app_ingress_to_vpc_endpoints" {
  security_group_id = var.vpc_endpoints_security_group_id

  type      = "ingress"
  from_port = 443
  to_port   = 443
  protocol  = "tcp"

  source_security_group_id = aws_security_group.metrics_service_out.id
}
