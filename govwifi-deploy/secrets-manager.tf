data "aws_secretsmanager_secret_version" "github_token" {
  secret_id = data.aws_secretsmanager_secret.github_token.id
}

data "aws_secretsmanager_secret" "github_token" {
  name = "github/deployment-user"
}

data "aws_secretsmanager_secret_version" "staging_aws_account_no" {
  secret_id = data.aws_secretsmanager_secret.staging_aws_account_no.id
}

data "aws_secretsmanager_secret" "staging_aws_account_no" {
  name = "staging/AccountID"
}

data "aws_secretsmanager_secret_version" "docker_hub_authtoken" {
  secret_id = data.aws_secretsmanager_secret.docker_hub_authtoken.id
}

data "aws_secretsmanager_secret" "docker_hub_authtoken" {
  name = "deploy/docker_hub_authtoken"
}

data "aws_secretsmanager_secret_version" "docker_hub_username" {
  secret_id = data.aws_secretsmanager_secret.docker_hub_username.id
}

data "aws_secretsmanager_secret" "docker_hub_username" {
  name = "deploy/docker_hub_username"
}
