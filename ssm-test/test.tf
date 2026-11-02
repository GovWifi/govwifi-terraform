## check can't coexist with "verify_live_ssm_roundtrip" because they both use the same resources and outputs.
# The "verify_live_ssm_roundtrip" test is a more comprehensive test that covers all of the same assertions as the individual checks below,
# so we can remove these individual checks to avoid redundancy.
# but wanted to keep for reference in case we want to split the tests up in future.

# check "validate_boolean" {
#   assert {
#     condition = (
#       local.reconstituted_bool == true
#     )
#     error_message = "Primitive boolean recovery failed."
#   }
# }

# check "validate_integer" {
#   assert {
#     condition = (
#       local.reconstituted_int == 8080
#     )
#     error_message = "Integer recovery failed."
#   }
# }

# check "validate_string" {
#   assert {
#     condition = (
#       local.reconstituted_string == "vpc-0123456789abcdef0"

#     )
#     error_message = "string recovery failed."
#   }
# }

# check "validate_secure_string" {
#   assert {
#     condition = (
#       local.reconstituted_secret == "SuperSecretGovWifiToken123!"
#     )
#     error_message = "KMS-encrypted recovery failed."
#   }
# }

# check "validate_list_fidelity" {
#   assert {
#     condition     = local.reconstituted_list == tolist(local.source_list)
#     error_message = "Decoded list does not match source list."
#   }
# }

# check "validate_map_fidelity" {
#   assert {
#     condition     = local.reconstituted_map.cost_center == local.source_map.cost_center && local.reconstituted_map.auto_scaling == true
#     error_message = "Decoded map lost primitive types (numbers/booleans)."
#   }
# }

# check "validate_nested_object_fidelity" {
#   assert {
#     condition     = local.reconstituted_nested.private_subnets[0].az == "eu-west-1a" && local.reconstituted_nested.security_rules.ingress_ports[1] == 443
#     error_message = "Nested navigation failed or array indexing corrupted."
#   }
# }