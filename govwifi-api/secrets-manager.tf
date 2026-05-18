data "aws_secretsmanager_secret_version" "session_db" {
  secret_id = data.aws_secretsmanager_secret.session_db.id
}

data "aws_secretsmanager_secret" "session_db" {
  name = "rds/session-db/credentials"
}

data "aws_secretsmanager_secret_version" "users_db" {
  secret_id = data.aws_secretsmanager_secret.users_db.id
}

data "aws_secretsmanager_secret" "users_db" {
  name = "rds/users-db/credentials"
}

data "aws_secretsmanager_secret_version" "notify_api_key" {
  secret_id = data.aws_secretsmanager_secret.notify_api_key.id
}

data "aws_secretsmanager_secret" "notify_api_key" {
  name = "admin-api/notify-api-key"
}

data "aws_secretsmanager_secret_version" "notify_do_not_reply" {
  secret_id = data.aws_secretsmanager_secret.notify_do_not_reply.id
}

data "aws_secretsmanager_secret" "notify_do_not_reply" {
  name = "user-signup-api/notify-do-not-reply"
}

data "aws_secretsmanager_secret_version" "notify_support_reply" {
  secret_id = data.aws_secretsmanager_secret.notify_support_reply.id
}

data "aws_secretsmanager_secret" "notify_support_reply" {
  name = "user-signup-api/notify-support-reply"
}

data "aws_secretsmanager_secret_version" "notify_bearer_token" {
  secret_id = data.aws_secretsmanager_secret.notify_bearer_token.id
}

data "aws_secretsmanager_secret" "notify_bearer_token" {
  name = "user-signup-api/notify-bearer-token"
}

data "aws_secretsmanager_secret_version" "admin_db" {
  secret_id = data.aws_secretsmanager_secret.admin_db.id
}

data "aws_secretsmanager_secret" "admin_db" {
  name = "rds/admin-db/credentials"
}

data "aws_secretsmanager_secret_version" "database_s3_encryption" {
  secret_id = data.aws_secretsmanager_secret.database_s3_encryption.id
}

data "aws_secretsmanager_secret" "database_s3_encryption" {
  name = "rds/database-s3-encryption"
}

data "aws_secretsmanager_secret" "safe_restarter_sentry_dsn" {
  name = "sentry/safe_restarter_dsn"
}

data "aws_secretsmanager_secret" "authentication_api_sentry_dsn" {
  name = "sentry/authentication_api_dsn"
}

data "aws_secretsmanager_secret" "user_signup_api_sentry_dsn" {
  name = "sentry/user_signup_api_dsn"
}

data "aws_secretsmanager_secret" "logging_api_sentry_dsn" {
  name = "sentry/logging_api_dsn"
}

data "aws_secretsmanager_secret" "metrics_api_key" {
  name = "govwifi/metrics-api/key"
}

data "aws_secretsmanager_secret_version" "tools_account" {
  secret_id = data.aws_secretsmanager_secret.tools_account.id
}

data "aws_secretsmanager_secret" "tools_account" {
  name = "tools/AccountID"
}

data "aws_secretsmanager_secret_version" "tools_kms_key" {
  secret_id = data.aws_secretsmanager_secret.tools_kms_key.id
}

data "aws_secretsmanager_secret" "tools_kms_key" {
  name = "tools/codepipeline-kms-key-arn"
}

data "aws_secretsmanager_secret_version" "tools_kms_key_ireland" {
  secret_id = data.aws_secretsmanager_secret.tools_kms_key_ireland.id
}

data "aws_secretsmanager_secret" "tools_kms_key_ireland" {
  name = "tools/codepipeline-kms-key-arn-ireland"
}
