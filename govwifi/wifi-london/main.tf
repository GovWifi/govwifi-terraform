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
    #bucket = "${lower(local.product_name)}-${lower(local.env_name)}-${lower(var.aws_region_name)}-tfstate"
    #key    = "${lower(var.aws_region_name)}-tfstate"
    #region = "${var.aws_region}"
    bucket = "govwifi-wifi-london-tfstate"

    key    = "london-tfstate"
    region = "eu-west-2"
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
  alias  = "dublin"
  region = "eu-west-1"

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

data "terraform_remote_state" "dublin" {
  backend = "s3"

  config = {
    bucket = "govwifi-wifi-dublin-tfstate"
    key    = "dublin-tfstate"
    region = "eu-west-1"
  }
}

module "govwifi_keys" {
  providers = {
    aws = aws.main
  }

  source = "../../govwifi-keys"

  create_production_bastion_key = 1

  govwifi_bastion_key_name = "govwifi-bastion-key"
  govwifi_bastion_key_pub  = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDY/Q676Tp5CTpKWVksMPztERDdjWOrYFgVckF9IHGI2wC38ckWFiqawsEZBILUyNZgL/lnOtheN1UZtuGmUUkPxgtPw+YD6gMDcebhSX4wh9GM3JjXAIy9+V/WagQ84Pz10yIp+PlyzcQMu+RVRVzWyTYZUdgMsDt0tFdcgMgUc7FkC252CgtSZHpLXhnukG5KG69CoTO+kuak/k3vX5jwWjIgfMGZwIAq+F9XSIMAwylCmmdE5MetKl0Wx4EI/fm8WqSZXj+yeFRv9mQTus906AnNieOgOrgt4D24/JuRU1JTlZ35iNbOKcwlOTDSlTQrm4FA1sCllphhD/RQVYpMp6EV3xape626xwkucCC2gYnakxTZFHUIeWfC5aHGrqMOMtXRfW0xs+D+vzo3MCWepdIebWR5KVhqkbNUKHBG9e8oJbTYUkoyBZjC7LtI4fgB3+blXyFVuQoAzjf+poPzdPBfCC9eiUJrEHoOljO9yMcdkBfyW3c/o8Sd9PgNufc= bastion@govwifi"

  govwifi_key_name     = var.ssh_key_name
  govwifi_key_name_pub = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDJmLa/tF941z6Dh/jiZCH6Mw/JoTXGkILim/bgDc3PSBKXFmBwkAFUVgnoOUWJDXvZWpuBJv+vUu+ZlmlszFM00BRXpb4ykRuJxWIjJiNzGlgXW69Satl2e9d37ZtLwlAdABgJyvj10QEiBtB1VS0DBRXK9J+CfwNPnwVnfppFGP86GoqE2Il86t+BB/VC//gKMTttIstyl2nqUwkK3Epq66+1ol3AelmUmBjPiyrmkwp+png9F4B86RqSNa/drfXmUGf1czE4+H+CXqOdje2bmnrwxLQ8GY3MYpz0zTVrB3T1IyXXF6dcdcF6ZId9B/10jMiTigvOeUvraFEf9fK7 govwifi@govwifi"
}

# Global ====================================================================

module "govwifi_account" {
  providers = {
    aws = aws.main
  }

  source         = "../../govwifi-account"
  aws_account_id = local.aws_account_id
}

# ====================================================================

module "backend" {
  providers = {
    aws = aws.main
    # Instance-specific setup -------------------------------
  }

  source        = "../../govwifi-backend"
  env           = "production"
  env_name      = local.env_name
  env_subdomain = local.env_subdomain

  # AWS VPC setup -----------------------------------------
  aws_region      = var.aws_region
  aws_region_name = var.aws_region_name
  route53_zone_id = data.aws_route53_zone.main.zone_id
  vpc_cidr_block  = local.london_backend_vpc_cidr_block

  administrator_cidrs = var.administrator_cidrs
  frontend_radius_ips = local.frontend_radius_ips

  bastion_instance_type      = "t2.micro"
  bastion_ssh_key_name       = "govwifi-bastion-key"
  enable_bastion_monitoring  = true
  aws_account_id             = local.aws_account_id
  db_instance_count          = 1
  session_db_instance_type   = "db.m5.xlarge"
  session_db_storage_gb      = 1000
  db_backup_retention_days   = 7
  db_encrypt_at_rest         = true
  db_maintenance_window      = "wed:01:42-wed:02:12"
  db_backup_window           = "03:05-04:05"
  db_replica_count           = 1
  rr_instance_type           = "db.m5.xlarge"
  rr_storage_gb              = 1000
  critical_notifications_arn = module.london_critical_notifications.topic_arn
  capacity_notifications_arn = module.london_capacity_notifications.topic_arn
  user_replica_source_db     = "wifi-production-user-db"

  # Seconds. Set to zero to disable monitoring
  db_monitoring_interval = 60

  # Passed to application
  user_db_hostname      = var.user_db_hostname
  user_rr_hostname      = var.user_rr_hostname
  user_db_instance_type = "db.t3.medium"
  user_db_storage_gb    = 1000
  user_db_replica_count = 1

  prometheus_ip_london  = var.prometheus_ip_london
  prometheus_ip_ireland = var.prometheus_ip_ireland
  grafana_ip            = var.grafana_ip

  backup_mysql_rds = local.backup_mysql_rds

  db_storage_alarm_threshold = 32212254720
}

# London Frontend ======DIFFERENT AWS REGION===================================
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
  # LONDON
  aws_region = var.aws_region

  aws_region_name         = var.aws_region_name
  route53_zone_id         = data.aws_route53_zone.main.zone_id
  vpc_cidr_block          = "10.85.0.0/16"
  london_backend_vpc_cidr = module.backend.vpc_cidr_block
  rack_env                = "production"
  sentry_current_env      = "production"

  backend_vpc_id = module.backend.backend_vpc_id

  # Instance-specific setup -------------------------------
  radius_instance_count      = 3
  radius_task_count          = 9
  enable_detailed_monitoring = true

  # eg. dns records are generated for radius(N).x.service.gov.uk
  # where N = this base + 1 + server#
  dns_numbering_base = 3

  ami                   = var.ami
  ssh_key_name          = var.ssh_key_name
  frontend_docker_image = format("%s/frontend:production", local.docker_image_path)
  raddb_docker_image    = format("%s/raddb:production", local.docker_image_path)
  create_ecr            = 1

  admin_app_data_s3_bucket_name = module.govwifi_admin.app_data_s3_bucket_name

  logging_api_base_url = var.london_api_base_url
  auth_api_base_url    = var.london_api_base_url

  authentication_api_internal_dns_name = module.api.authentication_api_internal_dns_name
  logging_api_internal_dns_name        = one(module.api.logging_api_internal_dns_name)

  pagerduty_notifications_arn = module.region_pagerduty.topic_arn
  critical_notifications_arn  = module.london_critical_notifications.topic_arn

  bastion_server_ip = var.bastion_server_ip

  prometheus_ip_london  = var.prometheus_ip_london
  prometheus_ip_ireland = var.prometheus_ip_ireland

  prometheus_security_group_id = module.govwifi_prometheus.prometheus_security_group_id

  radius_cidr_blocks = [for ip in local.frontend_radius_ips : "${ip}/32"]
}

module "govwifi_admin" {
  providers = {
    aws             = aws.main
    aws.replication = aws.dublin
  }

  source        = "../../govwifi-admin"
  env_name      = local.env_name
  env_subdomain = local.env_subdomain
  env           = local.env
  log_retention = local.log_retention

  aws_region      = var.aws_region
  aws_region_name = var.aws_region_name
  vpc_id          = module.backend.backend_vpc_id
  instance_count  = 2

  vpc_endpoints_security_group_id = module.backend.vpc_endpoints_security_group_id

  route53_zone_id  = data.aws_route53_zone.main.zone_id
  route53_zone_arn = data.aws_route53_zone.main.arn

  admin_docker_image   = format("%s/admin:production", local.docker_image_path)
  rails_env            = "production"
  app_env              = "production"
  sentry_current_env   = "production"
  ecr_repository_count = 1

  subnet_ids = module.backend.backend_subnet_ids

  db_instance_type         = "db.t3.large"
  db_storage_gb            = 120
  db_backup_retention_days = 1
  db_encrypt_at_rest       = true
  db_maintenance_window    = "sat:00:42-sat:01:12"
  db_backup_window         = "03:42-04:42"
  db_monitoring_interval   = 60

  rr_db_host = "rr.london.wifi.service.gov.uk"
  rr_db_name = "govwifi_wifi"

  user_db_host = var.user_db_hostname
  user_db_name = "govwifi_production_users"

  critical_notifications_arn  = module.london_critical_notifications.topic_arn
  capacity_notifications_arn  = module.london_capacity_notifications.topic_arn
  pagerduty_notifications_arn = module.region_pagerduty.topic_arn

  rds_monitoring_role = module.backend.rds_monitoring_role

  london_radius_ip_addresses = var.london_radius_ip_addresses
  dublin_radius_ip_addresses = var.dublin_radius_ip_addresses
  public_google_api_key      = var.public_google_api_key

  logging_api_search_url = "https://api-elb.london.${local.env_subdomain}.service.gov.uk:8443/logging/authentication/events/search/"

  zendesk_api_endpoint = "https://govuk.zendesk.com/api/v2/"
  zendesk_api_user     = var.zendesk_api_user

  bastion_server_ip = var.bastion_server_ip

  elasticsearch_endpoint = module.govwifi_elasticsearch.endpoint

  frontend_cert_bucket     = module.frontend.frontend_certs_bucket_name
  trusted_certificates_key = module.frontend.trusted_certificates_key
}

module "api" {
  providers = {
    aws = aws.main
  }

  source        = "../../govwifi-api"
  env           = "production"
  env_name      = local.env_name
  env_subdomain = local.env_subdomain
  log_retention = local.log_retention

  backend_elb_count      = 1
  backend_instance_count = 3
  aws_account_id         = local.aws_account_id
  aws_region_name        = var.aws_region_name
  aws_region             = var.aws_region
  route53_zone_id        = data.aws_route53_zone.main.zone_id
  vpc_id                 = module.backend.backend_vpc_id

  vpc_endpoints_security_group_id = module.backend.vpc_endpoints_security_group_id

  devops_notifications_arn    = module.devops_notifications.topic_arn
  capacity_notifications_arn  = module.london_capacity_notifications.topic_arn
  critical_notifications_arn  = module.london_critical_notifications.topic_arn
  pagerduty_notifications_arn = module.region_pagerduty.topic_arn


  user_signup_docker_image      = format("%s/user-signup-api:production", local.docker_image_path)
  logging_docker_image          = format("%s/logging-api:production", local.docker_image_path)
  safe_restart_docker_image     = format("%s/safe-restarter:production", local.docker_image_path)
  backup_rds_to_s3_docker_image = format("%s/database-backup:production", local.docker_image_path)

  create_wordlist_bucket = true
  wordlist_file_path     = "../wordlist-short"
  ecr_repository_count   = 1

  db_hostname               = "db.${lower(var.aws_region_name)}.${local.env_subdomain}.service.gov.uk"
  rack_env                  = "production"
  app_env                   = "production"
  sentry_current_env        = "production"
  radius_server_ips         = local.frontend_radius_ips
  subnet_ids                = module.backend.backend_subnet_ids
  private_subnet_ids        = module.backend.backend_private_subnet_ids
  nat_gateway_elastic_ips   = module.backend.nat_gateway_elastic_ips
  notify_ips                = var.notify_ips
  user_db_hostname          = var.user_db_hostname
  user_rr_hostname          = var.user_rr_hostname
  user_signup_api_is_public = 1

  admin_app_data_s3_bucket_name = module.govwifi_admin.app_data_s3_bucket_name


  alb_permitted_security_groups = [
    module.frontend.load_balanced_frontend_service_security_group_id,
  ]

  # Dublin frontend VPC CIDR block
  alb_permitted_cidr_blocks = [
    "10.43.0.0/16"
  ]

  metrics_bucket_name     = module.govwifi_dashboard.metrics_bucket_name
  export_data_bucket_name = module.govwifi_dashboard.export_data_bucket_name

  backup_mysql_rds        = local.backup_mysql_rds
  rds_mysql_backup_bucket = module.backend.rds_mysql_backup_bucket

  low_cpu_threshold = 10

  elasticsearch_endpoint = module.govwifi_elasticsearch.endpoint
  smoke_test_ips         = module.london_tests_vpc.eip_public_ips
}

module "london_critical_notifications" {
  providers = {
    aws = aws.main
  }

  source = "../../sns-notification"

  topic_name = "govwifi-prod-london-critical"
  emails     = [var.critical_notification_email]
}

module "london_capacity_notifications" {
  providers = {
    aws = aws.main
  }

  source = "../../sns-notification"

  topic_name = "govwifi-prod-london-capacity"
  emails     = [var.capacity_notification_email]
}

module "devops_notifications" {
  providers = {
    aws = aws.main
  }

  source = "../../sns-notification"

  topic_name = "govwifi-prod-london-devops"
  emails     = [var.devops_notification_email]
}

module "route53_critical_notifications" {
  providers = {
    aws = aws.us_east_1
  }

  source = "../../sns-notification"

  topic_name = "govwifi-prod-london-r53-critical"
  emails     = [var.critical_notification_email]
}

locals {
  pagerduty_https_endpoint = jsondecode(data.aws_secretsmanager_secret_version.pagerduty_config.secret_string)["integration-url"]
}

module "region_pagerduty" {
  providers = {
    aws = aws.main
  }

  source = "../../govwifi-pagerduty-integration"

  sns_topic_subscription_https_endpoint = local.pagerduty_https_endpoint
}

module "govwifi_dashboard" {
  providers = {
    aws = aws.main
  }

  source   = "../../govwifi-dashboard"
  env_name = local.env_name
}

module "govwifi_prometheus" {
  providers = {
    aws = aws.main
  }

  source   = "../../govwifi-prometheus"
  env_name = local.env_name

  ssh_key_name = var.ssh_key_name

  frontend_vpc_id = module.frontend.frontend_vpc_id

  aws_region      = var.aws_region
  aws_region_name = var.aws_region_name

  aws_account_id = local.aws_account_id

  wifi_frontend_subnet       = module.frontend.frontend_subnet_id
  london_radius_ip_addresses = var.london_radius_ip_addresses
  dublin_radius_ip_addresses = var.dublin_radius_ip_addresses

  grafana_ip    = var.grafana_ip
  log_retention = local.log_retention
}

module "govwifi_grafana" {
  providers = {
    aws = aws.main
  }

  source                     = "../../govwifi-grafana"
  env_name                   = local.env_name
  env_subdomain              = local.env_subdomain
  aws_region                 = var.aws_region
  aws_region_name            = var.aws_region_name
  aws_account_id             = local.aws_account_id
  capacity_notifications_arn = module.london_capacity_notifications.topic_arn

  route53_zone_id = data.aws_route53_zone.main.zone_id

  ssh_key_name = var.ssh_key_name

  subnet_ids = module.backend.backend_subnet_ids

  backend_subnet_ids = module.backend.backend_subnet_ids

  vpc_id = module.backend.backend_vpc_id

  bastion_ip = var.bastion_server_ip

  administrator_cidrs = var.administrator_cidrs

  prometheus_ips = [
    var.prometheus_ip_london,
    var.prometheus_ip_ireland
  ]
  vpc_be_cidr_block = local.london_backend_vpc_cidr_block
}

module "govwifi_slack_alerts" {
  providers = {
    aws = aws.main
  }

  source = "../../govwifi-slack-alerts"

  london_critical_notifications_topic_arn = module.london_critical_notifications.topic_arn
  london_capacity_notifications_topic_arn = module.london_capacity_notifications.topic_arn
  dublin_critical_notifications_topic_arn = data.terraform_remote_state.dublin.outputs.dublin_critical_notifications_arn
  dublin_capacity_notifications_topic_arn = data.terraform_remote_state.dublin.outputs.dublin_capacity_notifications_arn

  route53_critical_notifications_topic_arn = module.route53_critical_notifications.topic_arn
  create_slack_alert                       = 1 # set to 1 to create config for slack chat bot.
}

module "govwifi_elasticsearch" {
  providers = {
    aws = aws.main
  }

  source         = "../../govwifi-elasticsearch"
  domain_name    = "${local.env_name}-elasticsearch"
  env_name       = local.env_name
  aws_region     = var.aws_region
  aws_account_id = local.aws_account_id
  vpc_id         = module.backend.backend_vpc_id
  vpc_cidr_block = module.backend.vpc_cidr_block

  backend_subnet_id = module.backend.backend_subnet_ids[0]
}

module "smoke_tests" {
  providers = {
    aws        = aws.main
    aws.dublin = aws.dublin
  }

  source = "../../govwifi-smoke-tests"

  aws_account_id             = local.aws_account_id
  env_subdomain              = local.env_subdomain
  env                        = local.env_name
  vpc_id                     = module.london_tests_vpc.vpc_id
  default_security_group_id  = module.london_tests_vpc.default_security_group_id
  smoketest_subnet_private_a = module.london_tests_vpc.subnet_private_a_id
  smoketest_subnet_private_b = module.london_tests_vpc.subnet_private_b_id
  create_slack_alert         = 1
  govwifi_phone_number       = "+447537417417"
  notify_field               = "govwifi"
  smoke_tests_repo_name      = "govwifi-smoke-tests-light"


  depends_on = [
    module.frontend,
    module.london_tests_vpc
  ]
}

module "canary_tests" {
  providers = {
    aws        = aws.main
    aws.dublin = aws.dublin
  }

  source = "../../govwifi-canary-tests"

  aws_account_id             = local.aws_account_id
  env_subdomain              = local.env_subdomain
  env                        = local.env_name
  vpc_id                     = module.london_tests_vpc.vpc_id
  default_security_group_id  = module.london_tests_vpc.default_security_group_id
  smoketest_subnet_private_a = module.london_tests_vpc.subnet_private_a_id
  smoketest_subnet_private_b = module.london_tests_vpc.subnet_private_b_id
  create_slack_alert         = 1
  canary_tests_repo_name     = "govwifi-canary-tests"


  depends_on = [
    module.frontend,
    module.london_tests_vpc
  ]
}

module "london_tests_vpc" {
  source                     = "../../govwifi_tests_vpc"
  env_subdomain              = local.env_subdomain
  smoketests_vpc_cidr        = var.smoketests_vpc_cidr
  smoketest_subnet_private_a = var.smoketest_subnet_private_a
  smoketest_subnet_private_b = var.smoketest_subnet_private_b
  smoketest_subnet_public_a  = var.smoketest_subnet_public_a
  smoketest_subnet_public_b  = var.smoketest_subnet_public_b
}

module "london_govwifi-ecs-update-service" {
  providers = {
    aws = aws.main
  }

  source = "../../govwifi-ecs-update-service"

  deployed_app_names = ["user-signup-api", "logging-api", "admin", "authentication-api"]

  env_name = "wifi"

  aws_account_id = local.aws_account_id
}

moved {
  from = module.govwifi-ecs-update-service
  to   = module.london_govwifi-ecs-update-service
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

module "govwifi_account_policy" {
  providers = {
    aws = aws.main
  }

  source = "../../govwifi-account-policy"

  aws_region     = "eu-west-2"
  env            = local.env
  aws_account_id = local.aws_account_id
  region_name    = "London"

}

provider "aws" {
  alias  = "useast"
  region = "us-east-1"

  default_tags {
    tags = {
      Environment = "Production"
    }
  }
}

module "govwifi_docs" {
  providers = {
    aws = aws.useast
  }

  source = "../../govwifi-docs"

  route53_zone_id            = data.aws_route53_zone.main.zone_id
  critical_notifications_arn = module.route53_critical_notifications.topic_arn



}
