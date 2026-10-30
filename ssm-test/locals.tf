locals {
  # Simple array / list of strings
  source_list = [
    "subnet-0123456789abcdef0",
    "subnet-0123456789abcdef1",
    "subnet-0123456789abcdef2"
  ]

  # Key-value map with heterogeneous primitive values
  source_map = {
    environment  = "dev"
    cost_center  = 4021
    auto_scaling = true
    primary_dns  = "10.0.0.2"
  }

  # Multi-level nested object (lists inside maps, maps inside maps)
  source_nested_object = {
    vpc_id         = "vpc-0aa11bb22cc33dd44"
    cidr_block     = "10.100.0.0/16"
    private_subnets = [
      {
        id   = "subnet-aaa"
        az   = "eu-west-1a"
        cidr = "10.100.1.0/24"
      },
      {
        id   = "subnet-bbb"
        az   = "eu-west-1b"
        cidr = "10.100.2.0/24"
      }
    ]
    security_rules = {
      ingress_ports = [80, 443]
      egress_all    = true
    }
  }
}

locals {
  reconstituted_list   = split(",", nonsensitive(data.aws_ssm_parameter.read_native_list.value))
  reconstituted_map    = jsondecode(nonsensitive(data.aws_ssm_parameter.read_json_map.value))
  reconstituted_nested = jsondecode(nonsensitive(data.aws_ssm_parameter.read_json_nested.value))
}