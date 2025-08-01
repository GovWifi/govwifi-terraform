locals {
  env_name      = "wifi"
  env_subdomain = "wifi" # Environment specific subdomain to use under the service domain
  env           = "production"

  product_name = "GovWifi"

  backup_mysql_rds              = true
  london_backend_vpc_cidr_block = "10.84.0.0/16"
  log_retention                 = 365
}

locals {
  aws_account_id = data.aws_caller_identity.current.account_id
}

locals {
  docker_image_path = nonsensitive(jsondecode(data.aws_secretsmanager_secret_version.docker_image_path.secret_string)["path"])
}

locals {
  frontend_radius_ips = concat(var.london_radius_ip_addresses, var.dublin_radius_ip_addresses)
}
