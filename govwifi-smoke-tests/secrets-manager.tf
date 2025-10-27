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

data "aws_secretsmanager_secret_version" "slack_alert_url" {
  count     = (var.create_slack_alert == 1 ? 1 : 0)
  secret_id = data.aws_secretsmanager_secret.slack_alert_url[0].id
}

data "aws_secretsmanager_secret" "slack_alert_url" {
  count = (var.create_slack_alert == 1 ? 1 : 0)
  name  = "smoketests/slack-alert-url"
}

data "aws_secretsmanager_secret_version" "gw_user" {
  secret_id = data.aws_secretsmanager_secret.gw_user.id
}

data "aws_secretsmanager_secret" "gw_user" {
  name = "deploy/gw_user"
}

data "aws_secretsmanager_secret_version" "gw_pass" {
  secret_id = data.aws_secretsmanager_secret.gw_pass.id
}

data "aws_secretsmanager_secret" "gw_pass" {
  name = "deploy/gw_pass"
}

data "aws_secretsmanager_secret_version" "gw_2fa_secret" {
  secret_id = data.aws_secretsmanager_secret.gw_2fa_secret.id
}

data "aws_secretsmanager_secret" "gw_2fa_secret" {
  name = "deploy/gw_2fa_secret"
}

data "aws_secretsmanager_secret_version" "gw_super_admin_user" {
  secret_id = data.aws_secretsmanager_secret.gw_super_admin_user.id
}

data "aws_secretsmanager_secret" "gw_super_admin_user" {
  name = "deploy/gw_super_admin_user"
}

data "aws_secretsmanager_secret_version" "gw_super_admin_pass" {
  secret_id = data.aws_secretsmanager_secret.gw_super_admin_pass.id
}

data "aws_secretsmanager_secret" "gw_super_admin_pass" {
  name = "deploy/gw_super_admin_pass"
}

data "aws_secretsmanager_secret_version" "gw_super_admin_2fa_secret" {
  secret_id = data.aws_secretsmanager_secret.gw_super_admin_2fa_secret.id
}

data "aws_secretsmanager_secret" "gw_super_admin_2fa_secret" {
  name = "deploy/gw_super_admin_2fa_secret"
}

data "aws_secretsmanager_secret_version" "notify_smoketest_api_key" {
  secret_id = data.aws_secretsmanager_secret.notify_smoketest_api_key.id
}

data "aws_secretsmanager_secret" "notify_smoketest_api_key" {
  name = "smoketests/notify_smoketest_api_key"
}

data "aws_secretsmanager_secret_version" "eap_tls_client_cert" {
  secret_id = data.aws_secretsmanager_secret.eap_tls_client_cert.id
}

data "aws_secretsmanager_secret" "eap_tls_client_cert" {
  name = "smoke_tests/certificates/public"
}

data "aws_secretsmanager_secret_version" "eap_tls_client_key" {
  secret_id = data.aws_secretsmanager_secret.eap_tls_client_key.id
}

data "aws_secretsmanager_secret" "eap_tls_client_key" {
  name = "smoke_tests/certificates/private"
}

data "aws_secretsmanager_secret_version" "google_api_credentials" {
  secret_id = data.aws_secretsmanager_secret.google_api_credentials.id
}

data "aws_secretsmanager_secret" "google_api_credentials" {
  name = "deploy/google_api_credentials"
}



data "aws_secretsmanager_secret_version" "google_api_token_data" {
  secret_id = data.aws_secretsmanager_secret.google_api_token_data.id
}

data "aws_secretsmanager_secret" "google_api_token_data" {
  name = "deploy/google_api_token_data"
}


data "aws_secretsmanager_secret_version" "radius_key" {
  secret_id = data.aws_secretsmanager_secret.radius_key.id
}

data "aws_secretsmanager_secret" "radius_key" {
  name = "deploy/radius_key"
}



data "aws_secretsmanager_secret_version" "radius_ips" {
  secret_id = data.aws_secretsmanager_secret.radius_ips.id
}

data "aws_secretsmanager_secret" "radius_ips" {
  name = "deploy/radius_ips"
}

data "aws_secretsmanager_secret_version" "radius_ips_dublin" {
  provider  = aws.dublin
  secret_id = data.aws_secretsmanager_secret.radius_ips_dublin.id
}

data "aws_secretsmanager_secret" "radius_ips_dublin" {
  provider = aws.dublin

  name = "smoke_tests/radius_ips/dublin"
}

data "aws_secretsmanager_secret_version" "radius_ips_london" {
  secret_id = data.aws_secretsmanager_secret.radius_ips_london.id
}

data "aws_secretsmanager_secret" "radius_ips_london" {
  name = "smoke_tests/radius_ips/london"
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
data "aws_secretsmanager_secret_version" "admin_db" {
  secret_id = data.aws_secretsmanager_secret.admin_db.id
}

data "aws_secretsmanager_secret" "admin_db" {
  name = "rds/admin-db/credentials"
}