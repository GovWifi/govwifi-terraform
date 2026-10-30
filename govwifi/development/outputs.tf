output "test_results" {
  description = "Passthrough from ssm test module"
  value       = module.govwifi20_ssm_test.test_results
}