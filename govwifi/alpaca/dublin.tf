locals {
  dublin_aws_region              = "eu-west-1"
  dublin_aws_region_name         = "Dublin"
  dublin_backend_vpc_cidr_block  = "10.104.0.0/16"
  dublin_frontend_vpc_cidr_block = "10.105.0.0/16"
}

provider "aws" {
  alias  = "dublin"
  region = local.dublin_aws_region

  default_tags {
    tags = {
      Environment = title(local.env_name)
    }
  }
  /* As tags are computed, terraform always thinks have checked, re: issue https://github.com/hashicorp/terraform-provider-aws/issues/18311#issuecomment-1544330448 */
  ignore_tags {
    keys = ["Environment", "Staging"]
  }
}

# Cross region peering

resource "aws_vpc_peering_connection" "dublin_frontend_to_london_backend" {
  provider = aws.dublin

  vpc_id      = module.dublin_frontend.frontend_vpc_id
  peer_vpc_id = module.london_backend.backend_vpc_id
  peer_region = local.london_aws_region

  # Because this is a cross region peering, accepting this happens below
  auto_accept = false
}

resource "aws_vpc_peering_connection_options" "dublin_frontend_to_london_backend" {
  vpc_peering_connection_id = aws_vpc_peering_connection.dublin_frontend_to_london_backend.id

  accepter {
    allow_remote_vpc_dns_resolution = true
  }

  depends_on = [
    aws_vpc_peering_connection_accepter.dublin_frontend_to_london_backend
  ]
}

resource "aws_vpc_peering_connection_accepter" "dublin_frontend_to_london_backend" {
  provider = aws.london

  vpc_peering_connection_id = aws_vpc_peering_connection.dublin_frontend_to_london_backend.id
  auto_accept               = true
}

data "aws_vpc" "dublin_frontend" {
  provider = aws.dublin

  id = module.dublin_frontend.frontend_vpc_id
}

data "aws_vpc" "london_backend" {
  provider = aws.london

  id = module.london_backend.backend_vpc_id
}

resource "aws_route" "frontend_to_backend_route" {
  provider = aws.dublin

  route_table_id            = data.aws_vpc.dublin_frontend.main_route_table_id
  destination_cidr_block    = one(data.aws_vpc.london_backend.cidr_block_associations).cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.dublin_frontend_to_london_backend.id
}

resource "aws_route" "backend_to_frontend_route" {
  provider = aws.london

  route_table_id            = data.aws_vpc.london_backend.main_route_table_id
  destination_cidr_block    = one(data.aws_vpc.dublin_frontend.cidr_block_associations).cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.dublin_frontend_to_london_backend.id
}

# Backend ==================================================================
module "dublin_backend" {
  providers = {
    aws = aws.dublin
  }

  source        = "../../govwifi-backend"
  env           = "alpaca"
  env_name      = local.env_name
  env_subdomain = local.env_subdomain

  # AWS VPC setup -----------------------------------------
  aws_region      = local.dublin_aws_region
  route53_zone_id = data.aws_route53_zone.main.zone_id
  aws_region_name = local.dublin_aws_region_name
  vpc_cidr_block  = "10.104.0.0/16"

  administrator_cidrs = var.administrator_cidrs
  frontend_radius_ips = local.frontend_radius_ips

  # Instance-specific setup -------------------------------
  enable_bastion = 0

  bastion_instance_type     = "t2.micro"
  bastion_server_ip         = module.london_backend.bastion_public_ip
  bastion_ssh_key_name      = "alpaca-bastion-20230120"
  enable_bastion_monitoring = false
  aws_account_id            = local.aws_account_id

  db_encrypt_at_rest       = true
  db_maintenance_window    = "sat:00:42-sat:01:12"
  db_backup_window         = "03:42-04:42"
  db_backup_retention_days = 1

  db_instance_count        = 0
  session_db_instance_type = ""
  session_db_storage_gb    = 0

  db_replica_count = 0
  rr_instance_type = ""
  rr_storage_gb    = 0

  user_db_replica_count  = 1
  user_replica_source_db = "arn:aws:rds:eu-west-2:${local.aws_account_id}:db:wifi-alpaca-user-db"
  user_rr_instance_type  = "db.t3.small"

  # TODO This should happen inside the module
  user_rr_hostname           = "users-rr.${lower(local.dublin_aws_region_name)}.${local.env_subdomain}.service.gov.uk"
  critical_notifications_arn = module.dublin_notifications.topic_arn
  capacity_notifications_arn = module.dublin_notifications.topic_arn

  # Seconds. Set to zero to disable monitoring
  db_monitoring_interval = 60

  # Passed to application
  user_db_hostname      = ""
  user_db_instance_type = ""
  user_db_storage_gb    = 0
  prometheus_ip_london  = module.london_prometheus.eip_public_ip
  prometheus_ip_ireland = module.london_prometheus.eip_public_ip
  grafana_ip            = module.london_grafana.eip_public_ip

  db_storage_alarm_threshold = 19327342936
}

# Emails ======================================================================
module "emails" {
  providers = {
    aws = aws.dublin
  }

  source = "../../govwifi-emails"

  product_name             = local.product_name
  env_name                 = local.env_name
  env_subdomain            = local.env_subdomain
  aws_account_id           = local.aws_account_id
  route53_zone_id          = data.aws_route53_zone.main.zone_id
  aws_region               = local.dublin_aws_region
  aws_region_name          = local.dublin_aws_region_name
  mail_exchange_server     = "10 inbound-smtp.eu-west-1.amazonaws.com"
  devops_notifications_arn = module.dublin_notifications.topic_arn
}

module "dublin_keys" {
  providers = {
    aws = aws.dublin
  }

  source = "../../govwifi-keys"

  govwifi_bastion_key_name = "alpaca-bastion-20230120"
  govwifi_bastion_key_pub  = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC/cSxMbS72i6FoirL80CP9GLU7fZ1mtwIg0hi8v8OuCKyR8JjYQejZpyCGSIb3KOXIQf51bUI2+GB8B+h+UpWwUIN5Ysepc4YKuTjped4Av7ybrHFsqkl+66/uQgDwGloU6UuksTiwLVK9sf2JcDztm8Bbef/5cunLfhR+yrvzebF9kK0tnZxORwS0gCXA0bdgoqCUfJHxogLaZV3A517bn60rHcdq55qgIjI4IxNxdKLcrWjwJPbgvqepX+YbeDWqXe6VoVkwCB+daM8SGMvmZyfu7fsJFkoga4D9ksGTKNFFlLPlp4RqEkYqHqZAX70XVg6z32yHZ99iP36wCYhw3AjhdUMDFpoXv2iPMkFNx+EyOC1DtQdrLa96QDPKk2FSmhE6kz0524TWogS/x/2zFtXZbyqhAfzoU36YgFm8RYeS6mSUkxP7IynKvHbjuMqsh34sWRRSl4OxDA8K2ps2Hu2O2lFM44Sr02TeKqnKJza07ZRcAl8AWjoyaarHZ6iHft7n4CjXHLy2CmstVCIsEfmv+aZvMe8qZ1tWSoE50/6XyDn9B1UMQNmSIX8InYvh0pXIA6q+Y7/PAROfOcT3rKLSUyFS6D/PGfbq/P8GbJIAImSGBhBs4GgawtR7+hIpjsQ2dWEXwzdWGFkvmWyai6SUkclBYJkQYd0VyQb61w== david.pye@GDS10381"
  
  create_production_bastion_key = 0

  govwifi_key_name     = var.ssh_key_name
  govwifi_key_name_pub = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC4q8NhyH2wtEj8CiqOn+4OFgrB6wZgdzB/qjEh1t7ATQwgkFii0vtsJIzTfOVyxLr0rF79TQCdy7RcVidnZJOoa6QYJRDUx61f2bSacDsiI04/6QSAzqYe0x12fDoRMZqU6GWN1tRY3HYGdLCSMo8QaYonpdiyuS2q+gzFl1V1pk2c3/VT0KhZMWPV1qh6y6uCV13CkiFEgRpqhWTxfagv38lCRFvgJVmNxXtwBME8lqAs7DRoxfD5WZ4oGWO+wCaw+3QgD6gGDMUxpLk1CtL0BVpZ73OGB1XW2atTf2Ugma1jLMvP5IIrEDhMfOEX4iFexRVZBTqIqmsFaHjTH6BRp0J5FJ4suDVIv9eMblgZEGomDmP/T3ZIUq+96Z5BcOLpW1dEdCswbXtzuw7F+hIceSbnYMefSJ/8mhjxTcvBrJK4pv/BKEx/1UBOYtcwu3PZ52oiQaFFxElJiFTa/SUTLAks50e90o7kIZo2z4eal2e5mvWLSNwjA5kCniATfTs= govwifi-developers@digital.cabinet-office.gov.uk"

}

# Frontend ====================================================================
module "dublin_frontend" {
  providers = {
    aws           = aws.dublin
    aws.us_east_1 = aws.us_east_1
  }

  source         = "../../govwifi-frontend"
  env_name       = local.env_name
  env_subdomain  = local.env_subdomain
  env            = local.env
  aws_account_id = local.aws_account_id
  log_retention  = local.log_retention

  # AWS VPC setup -----------------------------------------
  aws_region         = local.dublin_aws_region
  aws_region_name    = local.dublin_aws_region_name
  route53_zone_id    = data.aws_route53_zone.main.zone_id
  vpc_cidr_block     = local.dublin_frontend_vpc_cidr_block
  rack_env           = "alpaca"
  sentry_current_env = "alpaca"

  backend_vpc_id = module.dublin_backend.backend_vpc_id

  # Instance-specific setup -------------------------------
  radius_instance_count      = 3
  radius_task_count          = 3
  enable_detailed_monitoring = false

  # eg. dns records are generated for radius(N).x.service.gov.uk
  # where N = this base + 1 + server#
  dns_numbering_base = 0

  ami          = "ami-2d386654"
  ssh_key_name = var.ssh_key_name

  frontend_docker_image = format(
    "%s/frontend:alpaca",
    replace(local.docker_image_path, local.london_aws_region, local.dublin_aws_region)
  )

  raddb_docker_image = format(
    "%s/raddb:alpaca",
    replace(local.docker_image_path, local.london_aws_region, local.dublin_aws_region)
  )

  admin_app_data_s3_bucket_name = module.london_admin.replica_app_data_s3_bucket_name

  logging_api_base_url = module.london_api.api_base_url
  auth_api_base_url    = module.dublin_api.api_base_url

  authentication_api_internal_dns_name = module.dublin_api.authentication_api_internal_dns_name
  logging_api_internal_dns_name        = one(module.london_api.logging_api_internal_dns_name)

  pagerduty_notifications_arn = module.dublin_notifications.topic_arn
  critical_notifications_arn  = module.dublin_notifications.topic_arn

  bastion_server_ip = module.london_backend.bastion_public_ip

  prometheus_ip_london  = module.london_prometheus.eip_public_ip
  prometheus_ip_ireland = module.london_prometheus.eip_public_ip

  prometheus_security_group_id = module.dublin_prometheus.prometheus_security_group_id

  radius_cidr_blocks = [for ip in local.frontend_radius_ips : "${ip}/32"]

  london_backend_vpc_cidr = module.london_backend.vpc_cidr_block
}

module "dublin_api" {
  providers = {
    aws = aws.dublin
  }

  source        = "../../govwifi-api"
  env           = "alpaca"
  env_name      = "alpaca"
  env_subdomain = local.env_subdomain
  log_retention = local.log_retention

  backend_elb_count      = 1
  backend_instance_count = 2
  aws_account_id         = local.aws_account_id
  aws_region_name        = local.dublin_aws_region_name
  aws_region             = local.dublin_aws_region
  route53_zone_id        = data.aws_route53_zone.main.zone_id
  vpc_id                 = module.dublin_backend.backend_vpc_id

  vpc_endpoints_security_group_id = module.dublin_backend.vpc_endpoints_security_group_id

  user_signup_enabled  = 0
  logging_enabled      = 0
  alarm_count          = 0
  safe_restart_enabled = 0
  event_rule_count     = 0

  critical_notifications_arn  = module.dublin_critical_notifications.topic_arn
  capacity_notifications_arn  = module.dublin_notifications.topic_arn
  devops_notifications_arn    = module.dublin_notifications.topic_arn
  pagerduty_notifications_arn = module.dublin_notifications.topic_arn

  user_signup_docker_image      = ""
  logging_docker_image          = ""
  safe_restart_docker_image     = ""
  backup_rds_to_s3_docker_image = ""

  db_hostname = ""

  user_db_hostname = ""
  ## TODO This should depend on the resource
  user_rr_hostname = "users-rr.${lower(local.dublin_aws_region_name)}.${local.env_subdomain}.service.gov.uk"

  rack_env                = "alpaca"
  app_env                 = "alpaca"
  sentry_current_env      = "alpaca"
  radius_server_ips       = local.frontend_radius_ips
  subnet_ids              = module.dublin_backend.backend_subnet_ids
  private_subnet_ids      = module.dublin_backend.backend_private_subnet_ids
  nat_gateway_elastic_ips = module.dublin_backend.nat_gateway_elastic_ips
  rds_mysql_backup_bucket = module.dublin_backend.rds_mysql_backup_bucket

  admin_app_data_s3_bucket_name = module.london_admin.app_data_s3_bucket_name

  alb_permitted_security_groups = [
    module.dublin_frontend.load_balanced_frontend_service_security_group_id
  ]

  low_cpu_threshold = 0.3
}

module "dublin_prometheus" {
  providers = {
    aws = aws.dublin
  }

  source          = "../../govwifi-prometheus"
  env_name        = local.env_name
  aws_region      = local.dublin_aws_region
  aws_region_name = local.dublin_aws_region_name
  aws_account_id  = local.aws_account_id
  log_retention   = local.log_retention

  ssh_key_name = var.ssh_key_name

  frontend_vpc_id = module.dublin_frontend.frontend_vpc_id

  wifi_frontend_subnet       = module.dublin_frontend.frontend_subnet_id
  london_radius_ip_addresses = module.london_frontend.eip_public_ips
  dublin_radius_ip_addresses = module.dublin_frontend.eip_public_ips

  grafana_ip = module.london_grafana.eip_public_ip
}

module "dublin_route53_notifications" {
  providers = {
    aws = aws.us_east_1
  }

  source = "../../sns-notification"

  topic_name = "govwifi-alpaca-dublin"
  emails     = [var.notification_email]
}

module "dublin_notifications" {
  providers = {
    aws = aws.dublin
  }

  source = "../../sns-notification"

  topic_name = "govwifi-alpaca-dublin-capacity"
  emails     = [var.notification_email]
}

module "dublin_critical_notifications" {
  providers = {
    aws = aws.dublin
  }

  source = "../../sns-notification"

  topic_name = "govwifi-alpaca-dublin-critical"
  emails     = [var.notification_email]
}

module "dublin_govwifi-ecs-update-service" {
  providers = {
    aws = aws.dublin
  }

  source = "../../govwifi-ecs-update-service"

  deployed_app_names = ["authentication-api"]

  env_name = "alpaca"

  aws_account_id = local.aws_account_id
}

module "dublin_sync_certs" {
  providers = {
    aws = aws.dublin
  }

  source = "../../govwifi-sync-certs"

  env            = local.env
  aws_account_id = local.aws_account_id
  aws_region     = local.dublin_aws_region
  region_name    = local.dublin_aws_region_name

}
