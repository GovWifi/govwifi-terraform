output "api_base_url" {
  description = "Global base url for API endpoints"
  value       = "https://${aws_route53_record.elb[0].fqdn}:${aws_alb_listener.alb_listener.port}"
}

output "authentication_api_internal_dns_name" {
  value = aws_lb.authentication_api.dns_name
}

output "logging_api_internal_dns_name" {
  value = aws_lb.logging_api.*.dns_name
}

output "api_out_sg_id" {
  value = aws_security_group.api_out.id
}
