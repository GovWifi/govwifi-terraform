resource "aws_eip" "radius_eips" {
  count = var.radius_instance_count
  domain   = "vpc"

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name   = "${title(var.env_name)} Frontend Radius-${var.dns_numbering_base + count.index + 1}"
    Region = title(var.aws_region_name)
  }
}

