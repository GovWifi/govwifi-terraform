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