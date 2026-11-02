

output "test_results" {
  value = {
    # Boolean equality checks
    is_list_identical   = local.reconstituted_list == tolist(local.source_list)
    is_map_identical    = local.reconstituted_map == local.source_map
    is_nested_identical = local.reconstituted_nested == local.source_nested_object
    is_bool_native_type   = can(local.reconstituted_bool == true)
    is_int_native_type    = can(local.reconstituted_int + 1 == 8081) # Arithmetic verification
    is_string_identical   = local.reconstituted_string == local.source_standalone_string
    is_kms_decrypted_ok   = local.reconstituted_secret == local.source_encrypted_secret

    # Direct nested element access
    extracted_nested_subnet_id = local.reconstituted_nested.private_subnets[0].id
    extracted_ingress_port     = local.reconstituted_nested.security_rules.ingress_ports[1]
    extracted_boolean_flag     = local.reconstituted_map.auto_scaling
    extracted_integer          = local.reconstituted_map.cost_center
    recovered_bool        = local.reconstituted_bool
    recovered_int         = local.reconstituted_int
    recovered_string      = local.reconstituted_string
    recovered_secret      = local.reconstituted_secret
  }
}
