output "cluster_id" {
  description = "The ID of the RDS cluster"
  value       = aws_rds_cluster.metrics-db-cluster.id
}

output "cluster_arn" {
  description = "Amazon Resource Name (ARN) of cluster"
  value       = aws_rds_cluster.metrics-db-cluster.arn
}

output "cluster_endpoint" {
  description = "Writer endpoint for the cluster"
  value       = aws_rds_cluster.metrics-db-cluster.endpoint
}

output "cluster_reader_endpoint" {
  description = "A read-only endpoint for the cluster"
  value       = aws_rds_cluster.metrics-db-cluster.reader_endpoint
}

output "cluster_database_name" {
  description = "Database name"
  value       = aws_rds_cluster.metrics-db-cluster.database_name
}
