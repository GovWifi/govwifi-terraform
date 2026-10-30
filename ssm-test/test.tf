check "validate_list_fidelity" {
  assert {
    condition     = local.reconstituted_list == tolist(local.source_list)
    error_message = "Decoded list does not match source list."
  }
}

check "validate_map_fidelity" {
  assert {
    condition     = local.reconstituted_map.cost_center == local.source_map.cost_center && local.reconstituted_map.auto_scaling == true
    error_message = "Decoded map lost primitive types (numbers/booleans)."
  }
}

check "validate_nested_object_fidelity" {
  assert {
    condition     = local.reconstituted_nested.private_subnets[0].az == "eu-west-1a" && local.reconstituted_nested.security_rules.ingress_ports[1] == 443
    error_message = "Nested navigation failed or array indexing corrupted."
  }
}