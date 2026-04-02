output "db_hostname" {
  value = aws_db_instance.admin_db.address
}

output "app_data_s3_bucket_name" {
  description = "Name (id) for the admin bucket"
  value       = aws_s3_bucket.admin_bucket.id
}

output "replica_app_data_s3_bucket_name" {
  description = "Name (id) for the replica admin bucket"
  value       = aws_s3_bucket.replication_admin_bucket.id
}

output "admin_ec2_out_sg_id" {
  value = aws_security_group.admin_ec2_out.id
}
