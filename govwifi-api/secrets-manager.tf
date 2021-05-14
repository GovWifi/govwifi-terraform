data "aws_secretsmanager_secret_version" "session_db" {
  secret_id = data.aws_secretsmanager_secret.session_db.id
}

data "aws_secretsmanager_secret" "session_db" {
  name = var.use_env_prefix ? "staging/rds/session-db/credentials" : "rds/session-db/credentials"
}

data "aws_secretsmanager_secret_version" "users_db" {
  secret_id = data.aws_secretsmanager_secret.users_db.id
}

data "aws_secretsmanager_secret" "users_db" {
  name = var.use_env_prefix ? "staging/rds/users-db/credentials" : "rds/users-db/credentials"
}

data "aws_secretsmanager_secret_version" "volumentrics_elasticsearch_endpoint" {
  secret_id = data.aws_secretsmanager_secret.volumentrics_elasticsearch_endpoint.id
}

data "aws_secretsmanager_secret" "volumentrics_elasticsearch_endpoint" {
  name = var.use_env_prefix ? "staging/logging-api/volumetrics-elasticsearch-endpoint" : "logging-api/volumetrics-elasticsearch-endpoint"
}

data "aws_secretsmanager_secret_version" "notify_api_key" {
  secret_id = data.aws_secretsmanager_secret.notify_api_key.id
}

data "aws_secretsmanager_secret" "notify_api_key" {
  name = var.use_env_prefix ? "staging/admin-api/notify-api-key" : "admin-api/notify-api-key"
}

data "aws_secretsmanager_secret_version" "notify_bearer_token" {
  secret_id = data.aws_secretsmanager_secret.notify_bearer_token.id
}

data "aws_secretsmanager_secret" "notify_bearer_token" {
  name = var.use_env_prefix ? "staging/user-signup-api/notify-bearer-token" : "user-signup-api/notify-bearer-token"
}