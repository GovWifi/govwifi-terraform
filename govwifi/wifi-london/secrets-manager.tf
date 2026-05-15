data "aws_secretsmanager_secret_version" "docker_image_path" {
  secret_id = data.aws_secretsmanager_secret.docker_image_path.id
}

data "aws_secretsmanager_secret" "docker_image_path" {
  name = "aws/ecr/docker-image-path/govwifi"
}

data "aws_secretsmanager_secret" "pagerduty_config" {
  name = "pagerduty/config"
}

data "aws_secretsmanager_secret_version" "pagerduty_config" {
  secret_id = data.aws_secretsmanager_secret.pagerduty_config.id
}

data "aws_secretsmanager_secret" "metrics_api_docker_image" {
  name = "govwifi/metrics/ecr/image"
}

data "aws_secretsmanager_secret_version" "metrics_api_docker_image" {
  secret_id = data.aws_secretsmanager_secret.metrics_api_docker_image.id
}

data "aws_secretsmanager_secret" "tableau_bridge_docker_image" {
  name = "govwifi/tableau-bridge/ecr/image"
}

data "aws_secretsmanager_secret_version" "tableau_bridge_docker_image" {
  secret_id = data.aws_secretsmanager_secret.tableau_bridge_docker_image.id
}
