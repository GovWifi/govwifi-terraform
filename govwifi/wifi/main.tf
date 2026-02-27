module "tfstate" {
  providers = {
    aws = aws.main
  }

  source             = "../../terraform-state"
  product_name       = local.product_name
  env_name           = local.env_name
  aws_account_id     = local.aws_account_id
  aws_region_name    = var.aws_region_name
  backup_region_name = var.backup_region_name

  # TODO: separate module for accesslogs
  accesslogs_glacier_transition_days = 30
  accesslogs_expiration_days         = 90
}

terraform {
  required_version = "~> 1.9.6"

  backend "s3" {
    # Interpolation is not allowed here.
    #bucket = "${lower(local.product_name)}-${lower(var.env_name)}-${lower(var.aws_region_name)}-tfstate"
    #key    = "${lower(var.aws_region_name)}-tfstate"
    #region = "${var.aws_region}"
    bucket = "govwifi-wifi-dublin-tfstate"

    key    = "dublin-tfstate"
    region = "eu-west-1"
  }
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  alias  = "main"
  region = var.aws_region

  default_tags {
    tags = {
      Environment = "Production"
    }
  }
}

provider "aws" {
  alias  = "london"
  region = "eu-west-2"

  default_tags {
    tags = {
      Environment = "Production"
    }
  }
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

  default_tags {
    tags = {
      Environment = "Production"
    }
  }
}

data "terraform_remote_state" "london" {
  backend = "s3"

  config = {
    bucket = "govwifi-wifi-london-tfstate"
    key    = "london-tfstate"
    region = "eu-west-2"
  }
}

module "govwifi_keys" {
  providers = {
    aws = aws.main
  }

  source = "../../govwifi-keys"

  govwifi_bastion_key_name = "govwifi-bastion-key"
  govwifi_bastion_key_pub  = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDY/Q676Tp5CTpKWVksMPztERDdjWOrYFgVckF9IHGI2wC38ckWFiqawsEZBILUyNZgL/lnOtheN1UZtuGmUUkPxgtPw+YD6gMDcebhSX4wh9GM3JjXAIy9+V/WagQ84Pz10yIp+PlyzcQMu+RVRVzWyTYZUdgMsDt0tFdcgMgUc7FkC252CgtSZHpLXhnukG5KG69CoTO+kuak/k3vX5jwWjIgfMGZwIAq+F9XSIMAwylCmmdE5MetKl0Wx4EI/fm8WqSZXj+yeFRv9mQTus906AnNieOgOrgt4D24/JuRU1JTlZ35iNbOKcwlOTDSlTQrm4FA1sCllphhD/RQVYpMp6EV3xape626xwkucCC2gYnakxTZFHUIeWfC5aHGrqMOMtXRfW0xs+D+vzo3MCWepdIebWR5KVhqkbNUKHBG9e8oJbTYUkoyBZjC7LtI4fgB3+blXyFVuQoAzjf+poPzdPBfCC9eiUJrEHoOljO9yMcdkBfyW3c/o8Sd9PgNufc= bastion@govwifi"

}

# Backend =====================================================================
module "backend" {
  providers = {
    aws = aws.main
  }

  source        = "../../govwifi-backend"
  env           = local.env
  env_name      = local.env_name
  env_subdomain = local.env_subdomain

  # AWS VPC setup -----------------------------------------
  aws_region      = var.aws_region
  aws_region_name = var.aws_region_name
  route53_zone_id = data.aws_route53_zone.main.zone_id
  vpc_cidr_block  = local.dublin_backend_vpc_cidr_block

  administrator_cidrs = var.administrator_cidrs
  frontend_radius_ips = local.frontend_radius_ips

  # Instance-specific setup -------------------------------
  # eu-west-1, CIS Ubuntu Linux 16.04 LTS Benchmark v1.0.0.4 - Level 1
  # bastion-ami = "ami-51d3e928"
  # eu-west-2 eu-west-2, CIS Ubuntu Linux 20.04 LTS
  bastion_instance_type     = "t2.micro"
  bastion_ssh_key_name      = "govwifi-bastion-key"
  enable_bastion_monitoring = true
  aws_account_id            = local.aws_account_id

  db_instance_count        = 0
  session_db_instance_type = "db.m5.xlarge"
  session_db_storage_gb    = 1000
  db_backup_retention_days = 7
  db_encrypt_at_rest       = true
  db_maintenance_window    = "sun:02:42-sun:03:12"
  db_backup_window         = "04:42-05:42"

  db_replica_count      = 0
  user_db_replica_count = 1
  rr_instance_type      = "db.m5.medium"
  rr_storage_gb         = 1000
  user_rr_instance_type = "db.m7g.large"

  critical_notifications_arn = module.dublin_critical_notifications.topic_arn
  capacity_notifications_arn = module.dublin_capacity_notifications.topic_arn
  user_replica_source_db     = "arn:aws:rds:eu-west-2:${local.aws_account_id}:db:wifi-production-user-db"

  # Seconds. Set to zero to disable monitoring
  db_monitoring_interval = 60

  # Passed to application
  user_db_instance_type = "db.t3.medium"
  user_db_hostname      = var.user_db_hostname
  user_db_storage_gb    = 20
  user_rr_hostname      = var.user_rr_hostname
  prometheus_ip_london  = var.prometheus_ip_london
  prometheus_ip_ireland = var.prometheus_ip_ireland
  grafana_ip            = var.grafana_ip

  db_storage_alarm_threshold = 32212254720
  recovery_backups_enabled   = false

}

# Emails ======================================================================
module "emails" {
  providers = {
    aws = aws.main
  }

  source = "../../govwifi-emails"

  product_name             = local.product_name
  env_name                 = local.env_name
  env_subdomain            = local.env_subdomain
  aws_account_id           = local.aws_account_id
  route53_zone_id          = data.aws_route53_zone.main.zone_id
  aws_region               = var.aws_region
  aws_region_name          = var.aws_region_name
  mail_exchange_server     = "10 inbound-smtp.eu-west-1.amazonaws.com"
  devops_notifications_arn = module.devops_notifications.topic_arn
}

# Global ====================================================================

module "dns" {
  providers = {
    aws = aws.main
  }

  source             = "../../global-dns"
  env_subdomain      = local.env_subdomain
  route53_zone_id    = data.aws_route53_zone.main.zone_id
  status_page_domain = "bl6klm1cjshh.stspg-customer.com"
}

# Frontend ====================================================================
module "frontend" {
  providers = {
    aws           = aws.main
    aws.us_east_1 = aws.us_east_1
  }

  source         = "../../govwifi-frontend"
  env_name       = local.env_name
  env_subdomain  = local.env_subdomain
  env            = local.env
  aws_account_id = local.aws_account_id
  log_retention  = local.log_retention

  # AWS VPC setup -----------------------------------------
  aws_region              = var.aws_region
  aws_region_name         = var.aws_region_name
  route53_zone_id         = data.aws_route53_zone.main.zone_id
  vpc_cidr_block          = local.dublin_frontend_vpc_cidr_block
  london_backend_vpc_cidr = local.london_backend_vpc_cidr_block
  rack_env                = "production"
  sentry_current_env      = local.env

  backend_vpc_id = module.backend.backend_vpc_id

  # Instance-specific setup -------------------------------
  radius_instance_count = 3
  radius_task_count     = 9
  radius_task_count_min = 9
  radius_task_count_max = 27

  enable_detailed_monitoring = true

  # eg. dns records are generated for radius(N).x.service.gov.uk
  # where N = this base + 1 + server#
  dns_numbering_base = 0

  ami          = var.ami
  ssh_key_name = var.ssh_key_name

  frontend_docker_image = format(
    "%s/frontend:production",
    replace(local.docker_image_path, "eu-west-2", "eu-west-1")
  )

  raddb_docker_image = format(
    "%s/raddb:production",
    replace(local.docker_image_path, "eu-west-2", "eu-west-1")
  )

  admin_app_data_s3_bucket_name = data.terraform_remote_state.london.outputs.replica_admin_app_data_s3_bucket_name

  logging_api_base_url = var.london_api_base_url
  auth_api_base_url    = var.dublin_api_base_url

  authentication_api_internal_dns_name = module.api.authentication_api_internal_dns_name
  logging_api_internal_dns_name        = one(data.terraform_remote_state.london.outputs.logging_api_internal_dns_name)

  pagerduty_notifications_arn = module.region_pagerduty.topic_arn
  critical_notifications_arn  = module.dublin_critical_notifications.topic_arn
  capacity_notifications_arn  = module.dublin_capacity_notifications.topic_arn

  bastion_server_ip = var.bastion_server_ip

  prometheus_ip_london  = var.prometheus_ip_london
  prometheus_ip_ireland = var.prometheus_ip_ireland

  prometheus_security_group_id = module.govwifi_prometheus.prometheus_security_group_id

  radius_cidr_blocks = [for ip in local.frontend_radius_ips : "${ip}/32"]
}

module "api" {
  providers = {
    aws = aws.main
  }

  env           = local.env
  source        = "../../govwifi-api"
  env_name      = local.env_name
  env_subdomain = local.env_subdomain
  log_retention = local.log_retention

  backend_elb_count        = 1
  task_count_min           = 2
  task_count_max           = 20
  authentication_api_count = 3
  aws_account_id           = local.aws_account_id
  aws_region_name          = lower(var.aws_region_name)
  aws_region               = var.aws_region
  route53_zone_id          = data.aws_route53_zone.main.zone_id
  vpc_id                   = module.backend.backend_vpc_id

  vpc_endpoints_security_group_id = module.backend.vpc_endpoints_security_group_id

  user_signup_enabled         = 0
  logging_enabled             = 0
  alarm_count                 = 0
  safe_restart_enabled        = 0
  event_rule_count            = 0
  devops_notifications_arn    = module.devops_notifications.topic_arn
  critical_notifications_arn  = module.dublin_critical_notifications.topic_arn
  capacity_notifications_arn  = module.dublin_capacity_notifications.topic_arn
  pagerduty_notifications_arn = module.region_pagerduty.topic_arn

  logging_docker_image          = format("%s/logging-api:production", local.docker_image_path)
  safe_restart_docker_image     = format("%s/safe-restarter:production", local.docker_image_path)
  backup_rds_to_s3_docker_image = ""

  db_hostname = "db.${lower(var.aws_region_name)}.${local.env_subdomain}.service.gov.uk"
  # TODO: need a Route53 record for read replica like db-rr.london.wifi.service.gov.uk
  # See https://788375279931-xinahcdw.us-east-1.console.aws.amazon.com/route53/v2/hostedzones?region=eu-west-2#ListRecordSets/Z1VHGR4MLZLL12
  # Using the RDS endpoint directly for now:
  db_read_replica_hostname = "wifi-db-rr.cs3igencwx07.eu-west-2.rds.amazonaws.com"
  rack_env                 = "production"
  app_env                  = local.env
  sentry_current_env       = local.env
  radius_server_ips        = local.frontend_radius_ips
  user_signup_docker_image = ""
  subnet_ids               = module.backend.backend_subnet_ids
  private_subnet_ids       = module.backend.backend_private_subnet_ids
  nat_gateway_elastic_ips  = module.backend.nat_gateway_elastic_ips
  user_db_hostname         = var.user_db_hostname
  user_rr_hostname         = var.user_rr_hostname
  rds_mysql_backup_bucket  = module.backend.rds_mysql_backup_bucket

  alb_permitted_security_groups = [
    module.frontend.load_balanced_frontend_service_security_group_id
  ]

  low_cpu_threshold = 10
}

module "dublin_critical_notifications" {
  providers = {
    aws = aws.main
  }

  source = "../../sns-notification"

  topic_name = "govwifi-prod-dublin-critical"
  emails     = [var.critical_notification_email]
}

module "dublin_capacity_notifications" {
  providers = {
    aws = aws.main
  }

  source = "../../sns-notification"

  topic_name = "govwifi-prod-dublin-capacity"
  emails     = [var.capacity_notification_email]
}

module "devops_notifications" {
  providers = {
    aws = aws.main
  }

  source = "../../sns-notification"

  topic_name = "govwifi-prod-dublin-devops"
  emails     = [var.devops_notification_email]
}

module "route53_critical_notifications" {
  providers = {
    aws = aws.us_east_1
  }

  source = "../../sns-notification"

  topic_name = "govwifi-prod-dublin-r53-critical"
  emails     = [var.critical_notification_email]
}

module "region_pagerduty" {
  providers = {
    aws = aws.main
  }

  source = "../../govwifi-pagerduty-integration"

  sns_topic_subscription_https_endpoint = local.pagerduty_https_endpoint
}

module "govwifi_prometheus" {
  providers = {
    aws = aws.main
  }

  source          = "../../govwifi-prometheus"
  env_name        = local.env_name
  aws_region      = var.aws_region
  aws_region_name = var.aws_region_name
  aws_account_id  = local.aws_account_id
  log_retention   = 30

  ssh_key_name = var.ssh_key_name

  frontend_vpc_id = module.frontend.frontend_vpc_id

  wifi_frontend_subnet       = module.frontend.frontend_subnet_id
  london_radius_ip_addresses = var.london_radius_ip_addresses
  dublin_radius_ip_addresses = var.dublin_radius_ip_addresses

  grafana_ip = var.grafana_ip
}

# Cross region VPC peering

resource "aws_vpc_peering_connection" "dublin_frontend_to_london_backend" {
  vpc_id      = module.frontend.frontend_vpc_id
  peer_vpc_id = data.terraform_remote_state.london.outputs.backend_vpc_id
  peer_region = "eu-west-2"

  # Because this is a cross region peering, accepting this happens below
  auto_accept = false
}

resource "aws_vpc_peering_connection_options" "dublin_frontend_to_london_backend" {
  provider = aws.london

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
  id = module.frontend.frontend_vpc_id
}

data "aws_vpc" "london_backend" {
  provider = aws.london

  id = data.terraform_remote_state.london.outputs.backend_vpc_id
}

resource "aws_route" "frontend_to_backend_route" {
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

module "dublin_govwifi-ecs-update-service" {
  providers = {
    aws = aws.main
  }

  source = "../../govwifi-ecs-update-service"

  deployed_app_names = ["authentication-api"]

  env_name = "wifi"

  aws_account_id = local.aws_account_id
}

moved {
  from = module.govwifi-ecs-update-service
  to   = module.dublin_govwifi-ecs-update-service
}

module "govwifi_sync_certs" {
  providers = {
    aws = aws.main
  }

  source = "../../govwifi-sync-certs"

  env            = local.env
  aws_account_id = local.aws_account_id
  aws_region     = var.aws_region
  region_name    = var.aws_region_name

}

module "dublin_log_management" {
  providers = {
    aws = aws.main
  }

  source                     = "../../log-management"
  env                        = local.env
  env_name                   = local.env_name
  aws_account_id             = local.aws_account_id
  region                     = var.aws_region
  region_name                = lower(var.aws_region_name)
  log_retention              = local.log_retention
  capacity_notifications_arn = module.dublin_capacity_notifications.topic_arn
}
