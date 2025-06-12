locals {
  env_name      = "alpaca"
  env_subdomain = "alpaca.wifi" # Environment specific subdomain to use under the service domain
  env           = "alpaca"
  product_name  = "GovWifi"

  backup_mysql_rds = true
  log_retention    = 30
}

locals {
  aws_account_id = data.aws_caller_identity.current.account_id
}

locals {
  docker_image_path = nonsensitive(jsondecode(data.aws_secretsmanager_secret_version.docker_image_path.secret_string)["path"])
}

locals {
  frontend_radius_ips = concat(
    module.london_frontend.eip_public_ips,
    module.dublin_frontend.eip_public_ips
  )
}
