# Global variable values passed into the test
variables {
  aws_region       = "eu-west-2"
  parameter_prefix = "/dev/govwifi20/tf-layers-test"
}

# -----------------------------------------------------------------------------
# Test 1: Validate payload structures at plan time (No AWS API calls made)
# -----------------------------------------------------------------------------
run "verify_plan_serialization" {
  module {
    source = "../../ssm-test"
  }
  command = plan

  assert {
    condition     = can(jsondecode(aws_ssm_parameter.json_map.value))
    error_message = "Nested contract is not valid JSON."
  }

  assert {
    condition     = aws_ssm_parameter.encrypted_secret.type == "SecureString"
    error_message = "Secret parameter was not configured as SecureString."
  }
}

# -----------------------------------------------------------------------------
# Test 2: Live Integration Test (Deploys, retrieves, asserts, auto-destroys)
# -----------------------------------------------------------------------------
run "verify_live_ssm_roundtrip" {
  module {
    source = "../../ssm-test"
  }
  command = apply

  # 1. Complex nested object validation
  assert {
    condition     = output.test_results.is_nested_identical == true
    error_message = "Nested object did not match."
  }

  assert {
    condition     = output.test_results.extracted_ingress_port == 443
    error_message = "Port extraction failed."
  }

  assert {
    condition     = output.test_results.extracted_nested_subnet_id == "subnet-aaa"
    error_message = "Nested array traversal failed inside object."
  }

  assert {
    condition     = output.test_results.extracted_ingress_port == 443
    error_message = "Nested integer array inside object corrupted."
  }

  # 2. Standalone boolean fidelity
  assert {
    condition     = output.test_results.is_bool_native_type == true
    error_message = "Standalone boolean was not parsed as native true."
  }

  # 3. Standalone integer fidelity (verify numeric arithmetic works)
  assert {
    condition     = output.test_results.is_int_native_type == true
    error_message = "Standalone int failed type match (not a native number)."
  }

  assert {
    condition     = output.test_results.recovered_int + 20== 8100
    error_message = "Standalone int failed mathematical evaluation (not a native number)."
  }

  # 4. Standard string fidelity
  assert {
    condition     = output.test_results.is_string_identical == true
    error_message = "Standard string does not match."
  }

  assert {
    condition     = output.test_results.recovered_string == "vpc-0123456789abcdef0"
    error_message = "Standard string corrupted."
  }

  # 5. KMS Decryption check
  assert {
    condition     = output.test_results.is_kms_decrypted_ok == true
    error_message = "KMS SecureString decryption failed."
  }

  assert {
    condition     = output.test_results.recovered_secret == "SuperSecretGovWifiToken123!"
    error_message = "KMS SecureString decryption failed."
  }
}