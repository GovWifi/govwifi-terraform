resource "random_uuid" "external_id" {
}

data "aws_secretsmanager_secret" "cribl_external_id" {
  name = "logs/cribl/external_id"
}

# Fetch the actual value
data "aws_secretsmanager_secret_version" "cribl_external_id_val" {
  secret_id = data.aws_secretsmanager_secret.cribl_external_id.id
}