
locals {
  db_creds     = jsondecode(data.aws_secretsmanager_secret_version.metrics_db_credentials_data.secret_string)
  database_dsn = "postgres://${local.db_creds["username"]}:${local.db_creds["password"]}@${aws_rds_cluster.metrics_db_cluster.endpoint}:5432/${var.database_name}"
}
