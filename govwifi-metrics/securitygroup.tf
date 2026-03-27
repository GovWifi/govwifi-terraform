resource "aws_security_group" "london_metrics_db_sg" {
  name        = "london-metrics-db"
  description = "Allow inbound traffic from backend to metrics DB"
  vpc_id      = var.backend_vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.backend_vpc_cidr_block]
  }

  tags = {
    Name = "${title(var.env)} London Metrics DB"
  }
}

resource "aws_db_subnet_group" "london_metrics_db_subnet_group" {
  name       = "london-metrics-subnets"
  subnet_ids = var.backend_subnet_ids

  tags = {
    Name = "${title(var.env)} London Metrics Subnets"
  }
}
