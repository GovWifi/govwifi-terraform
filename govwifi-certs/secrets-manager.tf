data "aws_secretsmanager_secret_version" "digicert_api_key" {
  secret_id = data.aws_secretsmanager_secret.digicert_api_key.id
}

data "aws_secretsmanager_secret" "digicert_api_key" {
  name = "cert_rotate/digicert_key"
}

data "aws_secretsmanager_secret_version" "csr_conf" {
  secret_id = data.aws_secretsmanager_secret.csr_conf.id
}

data "aws_secretsmanager_secret" "csr_conf" {
  name = "cert_rotate/csr_conf"
}

data "aws_secretsmanager_secret_version" "csr_file" {
  secret_id = data.aws_secretsmanager_secret.csr_file.id
}

data "aws_secretsmanager_secret" "csr_file" {
  name = "cert_rotate/csr_file"
}

data "aws_secretsmanager_secret_version" "dev_order_id" {
  secret_id = data.aws_secretsmanager_secret.order_id.id
}

data "aws_secretsmanager_secret" "dev_order_id" {
  name = "cert_rotate/dev_order_id"
}

data "aws_secretsmanager_secret_version" "frontend_cert_bucket_london" {
  secret_id = data.aws_secretsmanager_secret.frontend_cert_bucket_london.id
}

data "aws_secretsmanager_secret" "frontend_cert_bucket_london" {
  name = "cert_rotate/frontend_cert_bucket_london"
}
