# AWS Configuration
# CREATE VPC

resource "aws_vpc" "wifi_backend" {
  cidr_block = var.vpc_cidr_block

  # Hostnames required by the CIS hardened image.
  enable_dns_hostnames = true

  tags = {
    Name = "GovWifi Backend - ${var.env_name}"
  }
}

# CREATE GATEWAY AND DEFAULT ROUTE

resource "aws_internet_gateway" "wifi_backend" {
  vpc_id = aws_vpc.wifi_backend.id

  tags = {
    Name = "Backend Internet GW - ${var.env_name}"
  }
}

resource "aws_route" "internet_access" {
  route_table_id         = aws_vpc.wifi_backend.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.wifi_backend.id
}

data "aws_availability_zones" "zones" {}

resource "aws_subnet" "wifi_backend_subnet" {
  for_each = toset(data.aws_availability_zones.zones.names)

  vpc_id                  = aws_vpc.wifi_backend.id
  availability_zone       = each.key
  cidr_block              = "${join(".", slice(split(".", var.vpc_cidr_block), 0, 2))}.${index(data.aws_availability_zones.zones.names, each.key) + 1}.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.env_name} Backend - AZ: ${each.key} - GovWifi subnet"
  }
}

resource "aws_subnet" "wifi_backend_private_subnets" {
  # User api only exists in eu-west-2 so for the moment this resource
  # should only be created in the London region. The for_each statement
  # accomplishes this.
  for_each = {
    for key, value in data.aws_availability_zones.zones.names : value => value
    if var.aws_region == "eu-west-2"
  }

  vpc_id            = aws_vpc.wifi_backend.id
  availability_zone = each.value
  # Give private subnets their own distinct CIDR blocks
  cidr_block = "${join(".", slice(split(".", var.vpc_cidr_block), 0, 2))}.${index(data.aws_availability_zones.zones.names, each.value) + 6}.0/24"

  tags = {
    Name = "${var.env_name} Private Backend - AZ: ${each.value} - GovWifi subnet for user-api lambda"
  }
}

resource "aws_nat_gateway" "for_private_backend_subnets" {
  # User api only exists in eu-west-2 so for the moment this resource
  # should only be created in the London region. The for_each statement
  # accomplishes this.
  for_each = {
    for key, value in data.aws_availability_zones.zones.names : value => value
    if var.aws_region == "eu-west-2"
  }

  connectivity_type = "public"
  subnet_id         = aws_subnet.wifi_backend_subnet[each.value].id
  allocation_id     = aws_eip.for_nat_gateway_for_private_subnets[each.value].id

  tags = {
    Name        = "Lambda Nat Gateway -AZ- ${each.value}"
    Description = "Used to allow traffic out of lambda to reach the internet and connect with our User signup API"
  }
}

resource "aws_eip" "for_nat_gateway_for_private_subnets" {
  # User api only exists in eu-west-2 so for the moment this resource
  # should only be created in the London region. The for_each statement
  # accomplishes this.
  for_each = {
    for key, value in data.aws_availability_zones.zones.names : value => value
    if var.aws_region == "eu-west-2"
  }

  tags = {
    Name = "Nat Gateway for subnet in AZ ${each.value}"
  }

}

resource "aws_route_table" "user_api_lambda" {
  # User api only exists in eu-west-2 so for the moment this resource
  # should only be created in the London region. The for_each statement
  # accomplishes this.
  for_each = {
    for key, value in data.aws_availability_zones.zones.names : value => value
    if var.aws_region == "eu-west-2"
  }

  vpc_id = aws_vpc.wifi_backend.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.for_private_backend_subnets[each.value].id
  }

  tags = {
    Name = "Backend private subnets route table  - AZ: ${each.key}"
  }
}

resource "aws_route_table_association" "backend_private_subnets_route_tables" {
  # User api only exists in eu-west-2 so for the moment this resource
  # should only be created in the London region. The for_each statement
  # accomplishes this.
  for_each = {
    for key, value in data.aws_availability_zones.zones.names : value => value
    if var.aws_region == "eu-west-2"
  }
  subnet_id      = aws_subnet.wifi_backend_private_subnets[each.value].id
  route_table_id = aws_route_table.user_api_lambda[each.value].id
}

# log group for db backup
resource "aws_cloudwatch_log_group" "database_backup_log_group" {
  count             = var.backup_mysql_rds ? 1 : 0
  name              = "${var.env_name}-database-backup-log-group"
  retention_in_days = 30
}

# VPC Endpoints

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id            = aws_vpc.wifi_backend.id
  service_name      = "com.amazonaws.${var.aws_region}.ecr.dkr"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.vpc_endpoints.id,
  ]

  subnet_ids = [for subnet in aws_subnet.wifi_backend_subnet : subnet.id]

  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id            = aws_vpc.wifi_backend.id
  service_name      = "com.amazonaws.${var.aws_region}.ecr.api"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.vpc_endpoints.id,
  ]

  subnet_ids = [for subnet in aws_subnet.wifi_backend_subnet : subnet.id]

  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.wifi_backend.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [aws_vpc.wifi_backend.main_route_table_id]
}

resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id            = aws_vpc.wifi_backend.id
  service_name      = "com.amazonaws.${var.aws_region}.secretsmanager"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.vpc_endpoints.id,
  ]

  subnet_ids = [for subnet in aws_subnet.wifi_backend_subnet : subnet.id]

  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "logs" {
  vpc_id            = aws_vpc.wifi_backend.id
  service_name      = "com.amazonaws.${var.aws_region}.logs"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.vpc_endpoints.id,
  ]

  subnet_ids = [for subnet in aws_subnet.wifi_backend_subnet : subnet.id]

  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ssm" {
  vpc_id            = aws_vpc.wifi_backend.id
  service_name      = "com.amazonaws.${var.aws_region}.ssm"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.vpc_endpoints.id,
  ]

  subnet_ids = [for subnet in aws_subnet.wifi_backend_subnet : subnet.id]

  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id            = aws_vpc.wifi_backend.id
  service_name      = "com.amazonaws.${var.aws_region}.ssmmessages"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.vpc_endpoints.id,
  ]

  subnet_ids = [for subnet in aws_subnet.wifi_backend_subnet : subnet.id]

  private_dns_enabled = true
}
