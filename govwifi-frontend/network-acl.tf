
resource "aws_default_network_acl" "frontend_london" {
  count                  = var.aws_region == "eu-west-2" ? 1 : 0
  default_network_acl_id = var.bakend_default_network_acl_id
  subnet_ids             = var.backend_subnet_ids

  tags = {
    Name = "ACL GovWifi Frontend - ${var.env_name}"
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
  ingress {
    action          = "deny"
    cidr_block      = "192.168.0.0/16"
    from_port       = 0
    icmp_code       = 0
    icmp_type       = 0
    ipv6_cidr_block = null
    protocol        = "-1"
    rule_no         = 99
    to_port         = 0
  }
  ingress {
    action          = "deny"
    cidr_block      = "172.16.0.0/12"
    from_port       = 0
    icmp_code       = 0
    icmp_type       = 0
    ipv6_cidr_block = null
    protocol        = "-1"
    rule_no         = 98
    to_port         = 0
  }
  ingress {
    action          = "deny"
    cidr_block      = "10.0.0.0/8"
    from_port       = 0
    icmp_code       = 0
    icmp_type       = 0
    ipv6_cidr_block = null
    protocol        = "-1"
    rule_no         = 97
    to_port         = 0
  }

  ingress {
    action          = "allow"
    cidr_block      = var.vpc_cidr_block
    from_port       = 0
    icmp_code       = 0
    icmp_type       = 0
    ipv6_cidr_block = null
    protocol        = "-1"
    rule_no         = 96
    to_port         = 0
  }
  ingress {
    action          = "allow"
    cidr_block      = one(data.aws_vpc.backend.cidr_block_associations).cidr_block
    from_port       = 0
    icmp_code       = 0
    icmp_type       = 0
    ipv6_cidr_block = null
    protocol        = "-1"
    rule_no         = 95
    to_port         = 0
  }
}

resource "aws_default_network_acl" "frontend_dublin" {
  count                  = var.aws_region == "eu-west-1" ? 1 : 0
  default_network_acl_id = var.bakend_default_network_acl_id
  subnet_ids             = var.backend_subnet_ids

  tags = {
    Name = "ACL GovWifi Frontend - ${var.env_name}"
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
  ingress {
    action          = "deny"
    cidr_block      = "192.168.0.0/16"
    from_port       = 0
    icmp_code       = 0
    icmp_type       = 0
    ipv6_cidr_block = null
    protocol        = "-1"
    rule_no         = 99
    to_port         = 0
  }
  ingress {
    action          = "deny"
    cidr_block      = "172.16.0.0/12"
    from_port       = 0
    icmp_code       = 0
    icmp_type       = 0
    ipv6_cidr_block = null
    protocol        = "-1"
    rule_no         = 98
    to_port         = 0
  }
  ingress {
    action          = "deny"
    cidr_block      = "10.0.0.0/8"
    from_port       = 0
    icmp_code       = 0
    icmp_type       = 0
    ipv6_cidr_block = null
    protocol        = "-1"
    rule_no         = 97
    to_port         = 0
  }

  ingress {
    action          = "allow"
    cidr_block      = data.aws_vpc.backend.cidr_block
    from_port       = 0
    icmp_code       = 0
    icmp_type       = 0
    ipv6_cidr_block = null
    protocol        = "-1"
    rule_no         = 96
    to_port         = 0
  }
  ingress {
    action          = "allow"
    cidr_block      = one(data.aws_vpc.backend.cidr_block_associations).cidr_block
    from_port       = 0
    icmp_code       = 0
    icmp_type       = 0
    ipv6_cidr_block = null
    protocol        = "-1"
    rule_no         = 95
    to_port         = 0
  }
  ingress {
    action          = "allow"
    cidr_block      = var.london_backend_vpc_cidr
    from_port       = 0
    icmp_code       = 0
    icmp_type       = 0
    ipv6_cidr_block = null
    protocol        = "-1"
    rule_no         = 94
    to_port         = 0
  }
}

