
locals {
  db_creds     = jsondecode(data.aws_secretsmanager_secret_version.metrics_db_credentials_data.secret_string)
  database_dsn = "postgres://${local.db_creds["username"]}:${local.db_creds["password"]}@${aws_rds_cluster.metrics_db_cluster.endpoint}:5432/${var.database_name}"

  tableau_site         = data.aws_ssm_parameter.tableau_site.value
  tableau_user_email   = data.aws_ssm_parameter.tableau_user_email.value
  tableau_pat_token_id = data.aws_ssm_parameter.tableau_pat_token_id.value
  tableau_pool_id      = data.aws_ssm_parameter.tableau_pool_id.value
}
