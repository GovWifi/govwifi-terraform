resource "aws_default_network_acl" "backend_london" {
  count                  = var.aws_region == "eu-west-2" ? 1 : 0
  default_network_acl_id = aws_vpc.wifi_backend.default_network_acl_id
  subnet_ids             = [for subnet in aws_subnet.wifi_backend_private_subnets : subnet.id]

  tags = {
    Name = "ACL GovWifi Backend - ${var.env_name}"
  }

  egress {
    action          = "allow"
    cidr_block      = "0.0.0.0/0"
    from_port       = 0
    icmp_code       = 0
    icmp_type       = 0
    ipv6_cidr_block = null
    protocol        = "-1"
    rule_no         = 100
    to_port         = 0
  }
  ingress {
    action          = "allow"
    cidr_block      = "0.0.0.0/0"
    from_port       = 0
    icmp_code       = 0
    icmp_type       = 0
    ipv6_cidr_block = null
    protocol        = "-1"
    rule_no         = 100
    to_port         = 0
  }
}

resource "aws_default_network_acl" "backend_dublin" {
  count                  = var.aws_region == "eu-west-1" ? 1 : 0
  default_network_acl_id = aws_vpc.wifi_backend.default_network_acl_id
  subnet_ids             = [for subnet in aws_subnet.wifi_backend_private_subnets : subnet.id]

  tags = {
    Name = "ACL GovWifi Backend - ${var.env_name}"
  }

  egress {
    action          = "allow"
    cidr_block      = "0.0.0.0/0"
    from_port       = 0
    icmp_code       = 0
    icmp_type       = 0
    ipv6_cidr_block = null
    protocol        = "-1"
    rule_no         = 100
    to_port         = 0
  }
  ingress {
    action          = "allow"
    cidr_block      = "0.0.0.0/0"
    from_port       = 0
    icmp_code       = 0
    icmp_type       = 0
    ipv6_cidr_block = null
    protocol        = "-1"
    rule_no         = 100
    to_port         = 0
  }
}