module "tfstate" {
  providers = {
    aws = aws.main
  }

  source             = "../../terraform-state"
  product_name       = var.product_name
  env_name           = var.env_name
  aws_account_id     = local.aws_account_id
  aws_region_name    = var.aws_region_name
  backup_region_name = var.backup_region_name

  # TODO: separate module for accesslogs
  accesslogs_glacier_transition_days = 7
  accesslogs_expiration_days         = 30
}

terraform {
  required_version = "~> 0.15.5"

  backend "s3" {
    # Interpolation is not allowed here.
    #bucket = "${lower(var.product_name)}-${lower(var.env_name)}-${lower(var.aws_region_name)}-tfstate"
    #key    = "${lower(var.aws_region_name)}-tfstate"
    #region = "${var.aws_region}"
    bucket = "govwifi-staging-dublin-tfstate"

    key     = "dublin-tfstate"
    encrypt = true
    region  = "eu-west-1"
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
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

data "terraform_remote_state" "london" {
  backend = "s3"

  config = {
    bucket = "govwifi-staging-london-tfstate"
    key    = "staging-london-tfstate"
    region = "eu-west-2"
  }
}

# Backend ==================================================================
module "backend" {
  providers = {
    aws = aws.main
  }

  source                    = "../../govwifi-backend"
  env                       = "staging"
  env_name                  = var.env_name
  env_subdomain             = var.env_subdomain
  is_production_aws_account = var.is_production_aws_account


  # AWS VPC setup -----------------------------------------
  aws_region      = var.aws_region
  route53_zone_id = local.route53_zone_id
  aws_region_name = var.aws_region_name
  vpc_cidr_block  = "10.104.0.0/16"
  zone_count      = var.zone_count
  zone_names      = var.zone_names

  zone_subnets = {
    zone0 = "10.104.1.0/24"
    zone1 = "10.104.2.0/24"
    zone2 = "10.104.3.0/24"
  }

  administrator_ips   = var.administrator_ips
  frontend_radius_ips = local.frontend_radius_ips

  # Instance-specific setup -------------------------------
  # eu-west-1, CIS Ubuntu Linux 16.04 LTS Benchmark v1.0.0.4 - Level 1
  enable_bastion = 0
  #bastion-ami = "ami-51d3e928"
  # eu-west-2 eu-west-2, CIS Ubuntu Linux 20.04 LTS
  bastion_ami = "ami-08bac620dc84221eb"

  bastion_instance_type     = "t2.micro"
  bastion_server_ip         = var.bastion_server_ip
  bastion_ssh_key_name      = "staging-bastion-20200717"
  enable_bastion_monitoring = false
  users                     = var.users
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
  user_replica_source_db = "arn:aws:rds:eu-west-2:${local.aws_account_id}:db:wifi-staging-user-db"
  user_rr_instance_type  = "db.t2.small"

  user_rr_hostname           = var.user_rr_hostname
  critical_notifications_arn = module.notifications.topic_arn
  capacity_notifications_arn = module.notifications.topic_arn

  # Seconds. Set to zero to disable monitoring
  db_monitoring_interval = 60

  # Passed to application
  user_db_hostname      = ""
  user_db_instance_type = ""
  user_db_storage_gb    = 0
  prometheus_ip_london  = var.prometheus_ip_london
  prometheus_ip_ireland = var.prometheus_ip_ireland
  grafana_ip            = var.grafana_ip

  db_storage_alarm_threshold = 19327342936
}

# Emails ======================================================================
module "emails" {
  providers = {
    aws = aws.main
  }

  source = "../../govwifi-emails"

  is_production_aws_account = var.is_production_aws_account
  product_name              = var.product_name
  env_name                  = var.env_name
  env_subdomain             = var.env_subdomain
  aws_account_id            = local.aws_account_id
  route53_zone_id           = local.route53_zone_id
  aws_region                = var.aws_region
  aws_region_name           = var.aws_region_name
  mail_exchange_server      = "10 inbound-smtp.eu-west-1.amazonaws.com"
  devops_notifications_arn  = module.notifications.topic_arn

  user_signup_notifications_endpoint = "https://user-signup-api.${var.env_subdomain}.service.gov.uk:8443/user-signup/email-notification"

  // The SNS endpoint is disabled in the secondary AWS account
  // We will conduct an SNS inventory (see this card: https://trello.com/c/EMeet3tl/315-investigate-and-inventory-sns-topics)
  sns_endpoint = ""
}

module "govwifi_keys" {
  providers = {
    aws = aws.main
  }

  source = "../../govwifi-keys"

  govwifi_bastion_key_name = "staging-bastion-20200717"
  govwifi_bastion_key_pub  = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDL5wGVJ8aXL0QUhIvfLV2BMLC9Tk74jnChC40R9ipzK0AuatcaXdj0PEm8sh8sHlXEmdmVDq/4s8XaEkF7MDl38qbjxxHRTpCgcTrYzJGad3xgr1+zhpD8Kfnepex/2pR7z7kOCv7EDx4vRTc8vu1ttcmJiniBmgjc1xVk1A5aB72GxffZrow7B0iopP16vEPvllUjsDoOaeLJukDzsbZaP2RRYBqIA4qXunfJpuuu/o+T+YR4LkTB+9UBOOGrX50T80oTtJMKD9ndQ9CC9sqlrOzE9GiZz9db7D9iOzIZoTT6dBbgEOfCGmkj7WS2NjF+D/pEN/edkIuNGvE+J/HqQ179Xm/VCx5Kr6ARG+xk9cssCQbEFwR46yitaPA7B4mEiyD9XvUW2tUeVKdX5ybUFqV++2c5rxTczuH4gGlEGixIqPeltRvkVrN6qxnrbDAXE2bXymcnEN6BshwGKR+3OUKTS8c53eWmwiol6xwCp8VUI8/66tC/bCTmeur07z2LfQsIo745GzPuinWfUm8yPkZOD3LptkukO1aIfgvuNmlUKTwKSLIIwwsqTZ2FcK39A8g3Iq3HRV+4JwOowLJcylRa3QcSH9wdjd69SqPrZb0RhW0BN1mTX2tEBl1ryUUpKsqpMbvjl28tn6MGsU/sRhBLqliduOukGubD29LlAQ== "

  create_production_bastion_key = 0

  govwifi_key_name     = var.ssh_key_name
  govwifi_key_name_pub = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDOxYtGJARr+ZUB9wMWMX/H+myTidFKx+qcBsXuri5zavQ6K4c0WhSkypXfET9BBtC1ZU77B98mftegxKdKcKmFbCVlv39pIX+xj2vjuCzHlzezI1vB4mdAXNhc8b4ArvFJ8lG2GLa1ZD8H/8akpv6EcplwyUv6ZgQMPl6wfMF6d0Qe/eOJ/bV570icX9NYLGkdLRbudkRc12krt6h451qp1vO7f2FQOnPR2cnyLGd/FxhrmAOqJsDk9CRNSwHJe1lsSCz6TkQk1bfCTxZ7g2hWSNRBdWPj0RJbbezy3X3/pz4cFL8mCC1esJ+nptUZ7CXeyirtCObIepniXIItwtdIVqixaMSjfagUGd0L1zFEVuH0bct3mh3u3TyVbNHP4o4pFHvG0sm5R1iDB8/xe2NJdxmAsn3JqeXdsQ6uI/oz31OueFRPyZI0VeDw7B4bhBMZ0w/ncrYJ9jFjfPvzhAVZgQX5Pxtp5MUCeU9+xIdAN2bESmIvaoSEwno7WJ4z61d83pLMFUuS9vNRW4ykgd1BzatLYSkLp/fn/wYNn6DBk7Da6Vs1Y/jgkiDJPGeFlEhW3rqOjTKrpKJBw6LBsMyI0BtkKoPoUTDlKSEX5JlNWBX2z5eSEhe+WEQjc4ZnbLUOKRB5+xNOGahVyk7/VF8ZaZ3/GXWY7MEfZ8TIBBcAjw== "

}

# Frontend ====================================================================
module "frontend" {
  providers = {
    aws           = aws.main
    aws.us_east_1 = aws.us_east_1
  }

  source                    = "../../govwifi-frontend"
  env_name                  = var.env_name
  env_subdomain             = var.env_subdomain
  is_production_aws_account = var.is_production_aws_account

  # AWS VPC setup -----------------------------------------
  aws_region         = var.aws_region
  aws_region_name    = var.aws_region_name
  route53_zone_id    = local.route53_zone_id
  vpc_cidr_block     = "10.105.0.0/16"
  zone_count         = var.zone_count
  zone_names         = var.zone_names
  rack_env           = "staging"
  sentry_current_env = "secondary-staging"

  zone_subnets = {
    zone0 = "10.105.1.0/24"
    zone1 = "10.105.2.0/24"
    zone2 = "10.105.3.0/24"
  }

  # Instance-specific setup -------------------------------
  radius_instance_count      = 3
  enable_detailed_monitoring = false

  # eg. dns records are generated for radius(N).x.service.gov.uk
  # where N = this base + 1 + server#
  dns_numbering_base = 0

  elastic_ip_list       = local.frontend_region_ips
  ami                   = var.ami
  ssh_key_name          = var.ssh_key_name
  frontend_docker_image = format("%s/frontend:staging", local.docker_image_path)
  raddb_docker_image    = format("%s/raddb:staging", local.docker_image_path)

  admin_app_data_s3_bucket_name = data.terraform_remote_state.london.outputs.admin_app_data_s3_bucket_name

  logging_api_base_url = var.london_api_base_url
  auth_api_base_url    = var.dublin_api_base_url

  critical_notifications_arn            = module.notifications.topic_arn
  us_east_1_critical_notifications_arn  = module.route53_notifications.topic_arn
  us_east_1_pagerduty_notifications_arn = data.terraform_remote_state.london.outputs.us_east_1_notifications_topic_arn

  bastion_server_ip = var.bastion_server_ip

  prometheus_ip_london  = var.prometheus_ip_london
  prometheus_ip_ireland = var.prometheus_ip_ireland

  radius_cidr_blocks = [for ip in local.frontend_radius_ips : "${ip}/32"]

}

module "api" {
  providers = {
    aws = aws.main
  }

  source                    = "../../govwifi-api"
  env                       = "staging"
  env_name                  = "staging"
  env_subdomain             = var.env_subdomain
  is_production_aws_account = var.is_production_aws_account

  backend_elb_count      = 1
  backend_instance_count = 2
  aws_account_id         = local.aws_account_id
  aws_region_name        = var.aws_region_name
  aws_region             = var.aws_region
  route53_zone_id        = local.route53_zone_id
  vpc_id                 = module.backend.backend_vpc_id

  user_signup_enabled  = 0
  logging_enabled      = 0
  alarm_count          = 0
  safe_restart_enabled = 0
  event_rule_count     = 0

  devops_notifications_arn = module.notifications.topic_arn
  notification_arn         = module.notifications.topic_arn

  auth_docker_image             = format("%s/authorisation-api:staging", local.docker_image_path)
  user_signup_docker_image      = ""
  logging_docker_image          = ""
  safe_restart_docker_image     = ""
  backup_rds_to_s3_docker_image = ""

  db_hostname = ""

  user_db_hostname = ""
  user_rr_hostname = var.user_rr_hostname

  rack_env                  = "staging"
  sentry_current_env        = "secondary-staging"
  radius_server_ips         = local.frontend_radius_ips
  authentication_sentry_dsn = var.auth_sentry_dsn
  safe_restart_sentry_dsn   = ""
  subnet_ids                = module.backend.backend_subnet_ids
  backup_mysql_rds          = false
  rds_mysql_backup_bucket   = module.backend.rds_mysql_backup_bucket

  admin_app_data_s3_bucket_name = data.terraform_remote_state.london.outputs.admin_app_data_s3_bucket_name

  backend_sg_list = [
    module.backend.be_admin_in,
  ]

  low_cpu_threshold = 0.3
}

module "notifications" {
  providers = {
    aws = aws.main
  }

  source = "../../sns-notification"

  topic_name = "govwifi-staging"
  emails     = [var.notification_email]
}

module "route53_notifications" {
  providers = {
    aws = aws.us_east_1
  }

  source = "../../sns-notification"

  topic_name = "govwifi-staging-dublin"
  emails     = [var.notification_email]
}