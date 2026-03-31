data "aws_secretsmanager_secret" "metrics_db_credentials" {
  name = "metrics/db/credentials"
}

data "aws_secretsmanager_secret_version" "metrics_db_credentials_data" {
  secret_id = data.aws_secretsmanager_secret.metrics_db_credentials.id
}
