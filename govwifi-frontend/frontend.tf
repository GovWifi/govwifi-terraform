# AWS Configuration
# CREATE VPC

resource "aws_vpc" "wifi_frontend" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true

  tags = {
    Name = "GovWifi Frontend - ${var.env_name}"
  }
}

# CREATE GATEWAY AND DEFAULT ROUTE

resource "aws_internet_gateway" "wifi_frontend" {
  vpc_id = aws_vpc.wifi_frontend.id

  tags = {
    Name = "Frontend Internet GW - ${var.env_name}"
  }
}

resource "aws_route" "internet_access" {
  route_table_id         = aws_vpc.wifi_frontend.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.wifi_frontend.id
}

data "aws_availability_zones" "zones" {}

resource "aws_subnet" "wifi_frontend_subnet" {
  for_each = toset(data.aws_availability_zones.zones.names)

  vpc_id                  = aws_vpc.wifi_frontend.id
  availability_zone       = each.key
  cidr_block              = "${join(".", slice(split(".", var.vpc_cidr_block), 0, 2))}.${index(data.aws_availability_zones.zones.names, each.key) + 1}.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.env_name} Frontend - AZ: ${each.key} - GovWifi subnet"
  }
}
