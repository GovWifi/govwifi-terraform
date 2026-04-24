locals {
  env_name      = "staging"
  env_subdomain = "staging.wifi" # Environment specific subdomain to use under the service domain
  env           = "staging"
  product_name  = "GovWifi"

  backup_mysql_rds         = true
  log_retention            = 30
  recovery_backups_enabled = false

  tableau_site         = "cdioanalytics"
  tableau_user_email   = "govwifi-core-team@digital.cabinet-office.gov.uk"
  tableau_pat_token_id = "GovWifiDataBridge02"
  tableau_pool_id      = "c04ee3d4-10fd-44a3-a6a4-5d8096fa1f6d"
}

locals {
  aws_account_id = data.aws_caller_identity.current.account_id
}

locals {
  docker_image_path           = nonsensitive(jsondecode(data.aws_secretsmanager_secret_version.docker_image_path.secret_string)["path"])
  metrics_api_docker_image    = nonsensitive(data.aws_secretsmanager_secret_version.metrics_api_docker_image.secret_string)
  tableau_bridge_docker_image = nonsensitive(data.aws_secretsmanager_secret_version.tableau_bridge_docker_image.secret_string)
}

locals {
  frontend_radius_ips = concat(
    module.london_frontend.eip_public_ips,
    module.dublin_frontend.eip_public_ips
  )
}
