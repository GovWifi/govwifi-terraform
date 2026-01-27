/*
 Public VPC with two public subnets
*/

data "aws_availability_zones" "azs" {}

resource "aws_vpc" "capacity_public" {
	cidr_block = "10.222.0.0/16"
	tags = {
		Name = "govwifi-capacity-public-${var.env}"
		Env  = var.env
	}

	enable_dns_support = true
	enable_dns_hostnames = true
}

resource "aws_internet_gateway" "capacity_igw" {
	vpc_id = aws_vpc.capacity_public.id
	tags = { Name = "govwifi-capacity-igw-${var.env}" }
}

resource "aws_route_table" "capacity_public_rt" {
	vpc_id = aws_vpc.capacity_public.id
	route {
		cidr_block = "0.0.0.0/0"
		gateway_id = aws_internet_gateway.capacity_igw.id
	}
	tags = { Name = "govwifi-capacity-public-rt-${var.env}" }
}

resource "aws_subnet" "capacity_public" {
	count                   = 2
	vpc_id                  = aws_vpc.capacity_public.id
	cidr_block              = cidrsubnet(aws_vpc.capacity_public.cidr_block, 8, count.index)
	availability_zone       = data.aws_availability_zones.azs.names[count.index]
	map_public_ip_on_launch = true
	tags = {
		Name = "govwifi-capacity-public-${var.env}-${count.index}"
		Env  = var.env
	}
}

resource "aws_route_table_association" "capacity_public_rta" {
	count          = length(aws_subnet.capacity_public)
	subnet_id      = aws_subnet.capacity_public[count.index].id
	route_table_id = aws_route_table.capacity_public_rt.id
}

# Private subnets for ECS tasks to route through NAT
resource "aws_subnet" "capacity_private" {
	count             = 2
	vpc_id            = aws_vpc.capacity_public.id
	cidr_block        = cidrsubnet(aws_vpc.capacity_public.cidr_block, 8, count.index + 10)
	availability_zone = data.aws_availability_zones.azs.names[count.index]
	tags = {
		Name = "govwifi-capacity-private-${var.env}-${count.index}"
		Env  = var.env
	}
}

# Elastic IP for NAT gateway
resource "aws_eip" "nat_eip" {
	domain = "vpc"
	tags = { Name = "govwifi-capacity-nat-eip-${var.env}" }
	depends_on = [aws_internet_gateway.capacity_igw]
}

# NAT gateway in the first public subnet
resource "aws_nat_gateway" "capacity_nat" {
	allocation_id = aws_eip.nat_eip.id
	subnet_id     = aws_subnet.capacity_public[0].id
	tags = { Name = "govwifi-capacity-nat-${var.env}" }
	depends_on = [aws_internet_gateway.capacity_igw]
}

# Route table for private subnets pointing to NAT gateway
resource "aws_route_table" "capacity_private_rt" {
	vpc_id = aws_vpc.capacity_public.id
	route {
		cidr_block     = "0.0.0.0/0"
		nat_gateway_id = aws_nat_gateway.capacity_nat.id
	}
	tags = { Name = "govwifi-capacity-private-rt-${var.env}" }
}

# Associate private subnets with the private route table
resource "aws_route_table_association" "capacity_private_rta" {
	count          = length(aws_subnet.capacity_private)
	subnet_id      = aws_subnet.capacity_private[count.index].id
	route_table_id = aws_route_table.capacity_private_rt.id
}

