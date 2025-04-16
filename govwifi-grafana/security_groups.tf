resource "aws_security_group" "grafana_alb_in" {
  name        = "grafana-alb-in-${var.env_name}"
  description = "Allow Inbound Traffic to the Grafana ALB"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${title(var.env_name)} Grafana ALB Traffic In"
  }

  ingress {
    description = "grafana_alb_in_443"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.administrator_cidrs
  }
}

resource "aws_security_group" "grafana_alb_out" {
  name        = "grafana-alb-out-${var.env_name}"
  description = "Allow Outbound Traffic from the Grafana ALB"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${title(var.env_name)} Grafana ALB Traffic Out"
  }

  # Has an egress rule, defined as a separate resource below to avoid
  # creating a cycle between this group and the grafana-ec2-in
  # security group.
}

resource "aws_security_group_rule" "grafana_alb_out_egress" {
  description              = "grafana_alb_out_3000"
  type                     = "egress"
  from_port                = 3000
  to_port                  = 3000
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.grafana_ec2_in.id

  security_group_id = aws_security_group.grafana_alb_out.id
}

resource "aws_security_group" "grafana_ec2_in" {
  name        = "grafana-ec2-in-${var.env_name}"
  description = "Allow Inbound Traffic To Grafana from the ALB"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${title(var.env_name)} Grafana EC2 Traffic In"
  }

  ingress {
    description     = "grafana_ec2_in_3000"
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.grafana_alb_out.id]
  }
}

resource "aws_security_group" "grafana_ec2_out" {
  name        = "grafana-ec2-out-${var.env_name}"
  description = "Allow Outbound Traffic From the Grafana EC2 container"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${title(var.env_name)} Grafana EC2 Traffic Out"
  }

  egress {
    description = "grafana_ec2_out_9090"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = [for ip in var.prometheus_ips : "${ip}/32"]
  }

  # outbound 80 rule to allow package installs.
  egress {
    description = "grafana_ec2_out_80"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Cloudwatch Agent requires outbound to AWS
  egress {
    description = "grafana_ec2_out_443"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
