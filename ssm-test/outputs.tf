

output "test_results" {
  value = {
    # Boolean equality checks
    is_list_identical   = local.reconstituted_list == tolist(local.source_list)
    is_map_identical    = local.reconstituted_map == local.source_map
    is_nested_identical = local.reconstituted_nested == local.source_nested_object

    # Direct nested element access
    extracted_nested_subnet_id = local.reconstituted_nested.private_subnets[0].id
    extracted_ingress_port     = local.reconstituted_nested.security_rules.ingress_ports[1]
    extracted_boolean_flag     = local.reconstituted_map.auto_scaling
    extracted_integer          = local.reconstituted_map.cost_center
  }
}
