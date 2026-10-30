AWS SSM Parameter Store natively stores data as either String, StringList (comma-separated strings), or SecureString. While SSM does not have native HCL map or object schemas, complex data types (lists, maps, nested objects, booleans, and numbers) are handled cleanly by serializing them via jsonencode() on write and deserializing them via jsondecode() on read.   This avoids the blast-radius and security coupling problems of terraform_remote_state (which HashiCorp cautions against because state files expose raw values and couple module internals), while preserving type fidelity.Below is a self-contained test configuration containing lists, maps, and nested objects. It pushes them to SSM Parameter Store, reads them back using data sources, decodes them, and uses Terraform check blocks and outputs to verify type equality.

1. Complex Source Data Structures
2. Push Complex Structures into SSM Parameter Store
3. Read Values Back via SSM Data Sources
4. Deserialize Retrieved SSM Values
5. Automated Validation Checks (Requires Terraform >= 1.5)
6. Outputs for Manual Inspection

Expected output
```
test_results = {
  "extracted_boolean_flag"     = true
  "extracted_ingress_port"     = 443
  "extracted_integer"          = 4021
  "extracted_nested_subnet_id" = "subnet-aaa"
  "is_list_identical"          = true
  "is_map_identical"           = true
  "is_nested_identical"        = true
}
```