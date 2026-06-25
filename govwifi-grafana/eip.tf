resource "aws_eip" "grafana_eip" {
  domain = "vpc"

  tags = {
    Name = "grafana-${var.env_name}"
  }
}

resource "aws_eip_association" "grafana_eip_assoc" {
  instance_id   = aws_instance.grafana_instance.id
  allocation_id = aws_eip.grafana_eip.id
}

