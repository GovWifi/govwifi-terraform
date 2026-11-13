locals {
  frontend_metrics_namespace = "${var.env_name}-frontend"

  frontend_image_new = "${data.aws_secretsmanager_secret_version.tools_account.secret_string}.dkr.ecr.${var.aws_region}.amazonaws.com/govwifi/${var.env}/frontend:latest"
  raddb_image_new    = "${data.aws_secretsmanager_secret_version.tools_account.secret_string}.dkr.ecr.${var.aws_region}.amazonaws.com/govwifi/${var.env}/raddb:latest"

  tools_account_id = data.aws_secretsmanager_secret_version.tools_account.secret_string
}
