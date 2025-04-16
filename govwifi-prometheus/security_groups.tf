resource "aws_security_group" "prometheus" {
  name        = "prometheus-ec2-out-${var.env_name}"
  description = "Allows outbound traffic for the Prometheus server"
  vpc_id      = var.frontend_vpc_id

  tags = {
    Name = "${title(var.env_name)} Prometheus"
  }

  # for package installs
  egress {
    description = "prometheus_ec2_out_80"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # For cloudwatch agent
  egress {
    description = "prometheus_ec2_out_443"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # for NTP Time keeping
  egress {
    description = "prometheus_ec2_out_123"
    from_port   = 123
    to_port     = 123
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Free Radius connection
  egress {
    description = "Allow scraping the FreeRADIUS exporter"
    from_port   = 9812
    to_port     = 9812
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["${var.grafana_ip}/32"]
  }
}
