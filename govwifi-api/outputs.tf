output "authentication_api_internal_dns_name" {
  value = aws_lb.authentication_api.dns_name
}

output "logging_api_internal_dns_name" {
  value = aws_lb.logging_api.*.dns_name
}
