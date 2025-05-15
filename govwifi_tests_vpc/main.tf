resource "aws_vpc" "smoke_tests" {
  cidr_block = var.smoketests_vpc_cidr

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "Govwifi ${var.env_subdomain} Smoke-tests"
  }
}

resource "aws_internet_gateway" "smoke_tests" {
  vpc_id = aws_vpc.smoke_tests.id

  tags = {
    Name = "${var.env_subdomain}-smoke-tests"
  }
}

resource "aws_nat_gateway" "smoke_tests_a" {
  allocation_id = aws_eip.smoke_tests_a.id
  subnet_id     = aws_subnet.smoke_tests_public_a.id

  tags = {
    Name = "${var.env_subdomain}-public-smoke-tests-a"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.smoke_tests]
}

resource "aws_nat_gateway" "smoke_tests_b" {
  allocation_id = aws_eip.smoke_tests_b.id
  subnet_id     = aws_subnet.smoke_tests_public_b.id

  tags = {
    Name = "${var.env_subdomain}-public-smoke-tests-b"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.smoke_tests]
}

resource "aws_subnet" "smoke_tests_private_a" {
  vpc_id            = aws_vpc.smoke_tests.id
  cidr_block        = var.smoketest_subnet_private_a
  availability_zone = "eu-west-2a"

  tags = {
    Name = "${var.env_subdomain}-smoke-tests-private-a"
  }
}

resource "aws_subnet" "smoke_tests_private_b" {
  vpc_id            = aws_vpc.smoke_tests.id
  cidr_block        = var.smoketest_subnet_private_b
  availability_zone = "eu-west-2b"

  tags = {
    Name = "${var.env_subdomain}-smoke-tests-private-b"
  }
}

resource "aws_subnet" "smoke_tests_public_a" {
  vpc_id            = aws_vpc.smoke_tests.id
  cidr_block        = var.smoketest_subnet_public_a
  availability_zone = "eu-west-2a"

  tags = {
    Name = "${var.env_subdomain}-smoke-tests-public-a"
  }
}

resource "aws_subnet" "smoke_tests_public_b" {
  vpc_id            = aws_vpc.smoke_tests.id
  cidr_block        = var.smoketest_subnet_public_b
  availability_zone = "eu-west-2b"

  tags = {
    Name = "${var.env_subdomain}-smoke-tests-public-b"
  }
}



resource "aws_route_table" "smoke_tests_public" {
  vpc_id = aws_vpc.smoke_tests.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.smoke_tests.id
  }

  tags = {
    Name = "${var.env_subdomain}-public-smoke-tests"
  }
}

resource "aws_route_table_association" "smoke_tests_public_a" {
  subnet_id      = aws_subnet.smoke_tests_public_a.id
  route_table_id = aws_route_table.smoke_tests_public.id
}

resource "aws_route_table_association" "smoke_tests_public_b" {
  subnet_id      = aws_subnet.smoke_tests_public_b.id
  route_table_id = aws_route_table.smoke_tests_public.id
}


resource "aws_route_table" "smoke_tests_private_a" {
  vpc_id = aws_vpc.smoke_tests.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.smoke_tests_a.id
  }

  tags = {
    Name = "${var.env_subdomain}-smoke-tests-private-a"
  }
}

resource "aws_route_table_association" "smoke_tests_private_a" {
  subnet_id      = aws_subnet.smoke_tests_private_a.id
  route_table_id = aws_route_table.smoke_tests_private_a.id
}

resource "aws_route_table" "smoke_tests_private_b" {
  vpc_id = aws_vpc.smoke_tests.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.smoke_tests_b.id
  }

  tags = {
    Name = "${var.env_subdomain}-smoke-tests-private-b"
  }
}

resource "aws_route_table_association" "smoke_tests_private_b" {
  subnet_id      = aws_subnet.smoke_tests_private_b.id
  route_table_id = aws_route_table.smoke_tests_private_b.id
}

resource "aws_eip" "smoke_tests_a" {
  vpc = true
  tags = {
    Name = "${var.env_subdomain}-smoke-tests-a"
  }
}

resource "aws_eip" "smoke_tests_b" {
  vpc = true
  tags = {
    Name = "${var.env_subdomain}-smoke-tests-b"
  }
}
