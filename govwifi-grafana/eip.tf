resource "aws_eip" "grafana_eip" {
  instance = aws_instance.grafana_instance.id
  vpc      = true

  tags = {
    Name = "grafana-${var.Env-Name}"
    Env  = title(var.Env-Name)
  }
}

resource "aws_eip_association" "grafana_eip_assoc" {
  depends_on    = [aws_instance.grafana_instance]
  instance_id   = aws_instance.grafana_instance.id
  allocation_id = aws_eip.grafana_eip.id
}

