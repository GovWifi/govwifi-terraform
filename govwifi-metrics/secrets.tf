data "aws_secretsmanager_secret" "metrics_db_credentials" {
  name = "metrics/db/credentials"
}

data "aws_secretsmanager_secret_version" "metrics_db_credentials_data" {
  secret_id = data.aws_secretsmanager_secret.metrics_db_credentials.id
}

data "aws_secretsmanager_secret" "metrics_api_key" {
  name = "govwifi/metrics-api/key"
}

data "aws_secretsmanager_secret_version" "metrics_api_key_data" {
  secret_id = data.aws_secretsmanager_secret.metrics_api_key.id
}

data "aws_secretsmanager_secret" "metrics_data_publisher_tableau" {
  name = "govwifi/metrics-data-publisher/tableau"
}

data "aws_secretsmanager_secret_version" "metrics_data_publisher_tableau_data" {
  secret_id = data.aws_secretsmanager_secret.metrics_data_publisher_tableau.id
}

