output "vpc_id" {
  value = aws_vpc.smoke_tests.id
}

output "default_security_group_id" {
  value = aws_vpc.smoke_tests.default_security_group_id
}

output "subnet_private_a_id" {
  value = aws_subnet.smoke_tests_private_a.id
}

output "subnet_private_b_id" {
  value = aws_subnet.smoke_tests_private_b.id
}

output "subnet_public_a_id" {
  value = aws_subnet.smoke_tests_public_a.id
}

output "subnet_public_b_id" {
  value = aws_subnet.smoke_tests_public_b.id
}

output "eip_public_ips" {
  value = [aws_subnet.smoke_tests_public_a.id, aws_subnet.smoke_tests_public_b.id]
}
