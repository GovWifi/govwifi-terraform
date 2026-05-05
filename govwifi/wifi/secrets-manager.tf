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
