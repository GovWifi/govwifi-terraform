# Standalone Boolean (stored as JSON primitive)
resource "aws_ssm_parameter" "standalone_bool" {
  name  = "${var.parameter_prefix}/config/feature-flag-bool"
  type  = "String"
  value = jsonencode(local.source_standalone_bool)
  tier  = "Standard"
}

# Standalone Integer (stored as JSON primitive)
resource "aws_ssm_parameter" "standalone_int" {
  name  = "${var.parameter_prefix}/config/service-port-int"
  type  = "String"
  value = jsonencode(local.source_standalone_int)
  tier  = "Standard"
}

# Standard String (VPC ID)
resource "aws_ssm_parameter" "standard_string" {
  name  = "${var.parameter_prefix}/networking/vpc-id"
  type  = "String"
  value = local.source_standalone_string
  tier  = "Standard"
}

# KMS Encrypted SecureString (uses AWS default alias/aws/ssm; or specify key_id)
resource "aws_ssm_parameter" "encrypted_secret" {
  name   = "${var.parameter_prefix}/auth/shared-secret"
  type   = "SecureString"
  key_id = "alias/aws/ssm"
  value  = local.source_encrypted_secret
  tier   = "Standard"
}

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