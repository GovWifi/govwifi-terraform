output "frontend_vpc_id" {
  value = aws_vpc.wifi_frontend.id
}

output "frontend_subnet_id" {
  value = [for subnet in aws_subnet.wifi_frontend_subnet : subnet.id]
}

output "fe_ecs_out" {
  value = aws_security_group.fe_ecs_out.id
}

output "fe_radius_in" {
  value = aws_security_group.fe_radius_in.id
}

output "fe_radius_out" {
  value = aws_security_group.fe_radius_out.id
}

output "ecs_instance_profile" {
  value = aws_iam_instance_profile.ecs_instance_profile.id
}

output "eip_public_ips" {
  value = [for eip in aws_eip.radius_eips : eip.public_ip]
}

output "load_balanced_frontend_service_security_group_id" {
  value = aws_security_group.load_balanced_frontend_service.id
}

output "frontend_certs_bucket_name" {
  value = aws_s3_bucket.frontend_cert_bucket.bucket
}

output "trusted_certificates_key" {
  value = var.trusted_certificates_key
}
