# Method A: SSM Native StringList (best for simple flat string arrays)
resource "aws_ssm_parameter" "native_list" {
  name        = "${var.parameter_prefix}/networking/subnets-native"
  type        = "StringList"
  value       = join(",", local.source_list)
  description = "Native SSM comma-delimited string array"
  tier        = "Standard"
}

# Method B: JSON-encoded Map
resource "aws_ssm_parameter" "json_map" {
  name        = "${var.parameter_prefix}/config/app-map"
  type        = "String"
  value       = jsonencode(local.source_map)
  description = "HCL map encoded into a JSON string"
  tier        = "Standard"
}

# Method C: JSON-encoded Deeply Nested Object
resource "aws_ssm_parameter" "json_nested" {
  name        = "${var.parameter_prefix}/networking/vpc-contract"
  type        = "String"
  value       = jsonencode(local.source_nested_object)
  description = "Complex nested contract object encoded into JSON"
  tier        = "Standard"
}