locals {
  dublin_aws_region      = "eu-west-1"
  dublin_aws_region_name = "Dublin"
}

provider "aws" {
  alias  = "dublin"
  region = local.dublin_aws_region
}

# Backend ==================================================================
module "dublin_backend" {
  providers = {
    aws = aws.dublin
  }

  source        = "../../govwifi-backend"
  env           = "staging"
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
  bastion_ami    = "ami-08bac620dc84221eb"

  bastion_instance_type     = "t2.micro"
  bastion_server_ip         = module.london_backend.bastion_public_ip
  bastion_ssh_key_name      = "staging-bastion-20200717"
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
  user_replica_source_db = "arn:aws:rds:eu-west-2:${local.aws_account_id}:db:wifi-staging-user-db"
  user_rr_instance_type  = "db.t2.small"

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

  govwifi_bastion_key_name = "staging-bastion-20200717"
  govwifi_bastion_key_pub  = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDL5wGVJ8aXL0QUhIvfLV2BMLC9Tk74jnChC40R9ipzK0AuatcaXdj0PEm8sh8sHlXEmdmVDq/4s8XaEkF7MDl38qbjxxHRTpCgcTrYzJGad3xgr1+zhpD8Kfnepex/2pR7z7kOCv7EDx4vRTc8vu1ttcmJiniBmgjc1xVk1A5aB72GxffZrow7B0iopP16vEPvllUjsDoOaeLJukDzsbZaP2RRYBqIA4qXunfJpuuu/o+T+YR4LkTB+9UBOOGrX50T80oTtJMKD9ndQ9CC9sqlrOzE9GiZz9db7D9iOzIZoTT6dBbgEOfCGmkj7WS2NjF+D/pEN/edkIuNGvE+J/HqQ179Xm/VCx5Kr6ARG+xk9cssCQbEFwR46yitaPA7B4mEiyD9XvUW2tUeVKdX5ybUFqV++2c5rxTczuH4gGlEGixIqPeltRvkVrN6qxnrbDAXE2bXymcnEN6BshwGKR+3OUKTS8c53eWmwiol6xwCp8VUI8/66tC/bCTmeur07z2LfQsIo745GzPuinWfUm8yPkZOD3LptkukO1aIfgvuNmlUKTwKSLIIwwsqTZ2FcK39A8g3Iq3HRV+4JwOowLJcylRa3QcSH9wdjd69SqPrZb0RhW0BN1mTX2tEBl1ryUUpKsqpMbvjl28tn6MGsU/sRhBLqliduOukGubD29LlAQ== "

  create_production_bastion_key = 0

  govwifi_key_name     = var.ssh_key_name
  govwifi_key_name_pub = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDOxYtGJARr+ZUB9wMWMX/H+myTidFKx+qcBsXuri5zavQ6K4c0WhSkypXfET9BBtC1ZU77B98mftegxKdKcKmFbCVlv39pIX+xj2vjuCzHlzezI1vB4mdAXNhc8b4ArvFJ8lG2GLa1ZD8H/8akpv6EcplwyUv6ZgQMPl6wfMF6d0Qe/eOJ/bV570icX9NYLGkdLRbudkRc12krt6h451qp1vO7f2FQOnPR2cnyLGd/FxhrmAOqJsDk9CRNSwHJe1lsSCz6TkQk1bfCTxZ7g2hWSNRBdWPj0RJbbezy3X3/pz4cFL8mCC1esJ+nptUZ7CXeyirtCObIepniXIItwtdIVqixaMSjfagUGd0L1zFEVuH0bct3mh3u3TyVbNHP4o4pFHvG0sm5R1iDB8/xe2NJdxmAsn3JqeXdsQ6uI/oz31OueFRPyZI0VeDw7B4bhBMZ0w/ncrYJ9jFjfPvzhAVZgQX5Pxtp5MUCeU9+xIdAN2bESmIvaoSEwno7WJ4z61d83pLMFUuS9vNRW4ykgd1BzatLYSkLp/fn/wYNn6DBk7Da6Vs1Y/jgkiDJPGeFlEhW3rqOjTKrpKJBw6LBsMyI0BtkKoPoUTDlKSEX5JlNWBX2z5eSEhe+WEQjc4ZnbLUOKRB5+xNOGahVyk7/VF8ZaZ3/GXWY7MEfZ8TIBBcAjw== "

}

# Frontend ====================================================================
module "dublin_frontend" {
  providers = {
    aws           = aws.dublin
    aws.us_east_1 = aws.us_east_1
  }

  source        = "../../govwifi-frontend"
  env_name      = local.env_name
  env_subdomain = local.env_subdomain

  # AWS VPC setup -----------------------------------------
  aws_region         = local.dublin_aws_region
  aws_region_name    = local.dublin_aws_region_name
  route53_zone_id    = data.aws_route53_zone.main.zone_id
  vpc_cidr_block     = "10.105.0.0/16"
  rack_env           = "staging"
  sentry_current_env = "secondary-staging"

  # Instance-specific setup -------------------------------
  radius_instance_count      = 3
  enable_detailed_monitoring = false

  # eg. dns records are generated for radius(N).x.service.gov.uk
  # where N = this base + 1 + server#
  dns_numbering_base = 0

  ami                   = "ami-2d386654"
  ssh_key_name          = var.ssh_key_name
  frontend_docker_image = format("%s/frontend:staging", local.docker_image_path)
  raddb_docker_image    = format("%s/raddb:staging", local.docker_image_path)

  admin_app_data_s3_bucket_name = module.london_admin.app_data_s3_bucket_name

  logging_api_base_url = module.london_api.api_base_url
  auth_api_base_url    = module.dublin_api.api_base_url

  critical_notifications_arn            = module.dublin_notifications.topic_arn
  us_east_1_critical_notifications_arn  = module.dublin_route53_notifications.topic_arn
  us_east_1_pagerduty_notifications_arn = module.london_route53_notifications.topic_arn

  bastion_server_ip = module.london_backend.bastion_public_ip

  prometheus_ip_london  = module.london_prometheus.eip_public_ip
  prometheus_ip_ireland = module.london_prometheus.eip_public_ip

  radius_cidr_blocks = [for ip in local.frontend_radius_ips : "${ip}/32"]

}

module "dublin_api" {
  providers = {
    aws = aws.dublin
  }

  source        = "../../govwifi-api"
  env           = "staging"
  env_name      = "staging"
  env_subdomain = local.env_subdomain

  backend_elb_count      = 1
  backend_instance_count = 2
  aws_account_id         = local.aws_account_id
  aws_region_name        = local.dublin_aws_region_name
  aws_region             = local.dublin_aws_region
  route53_zone_id        = data.aws_route53_zone.main.zone_id
  vpc_id                 = module.dublin_backend.backend_vpc_id

  user_signup_enabled  = 0
  logging_enabled      = 0
  alarm_count          = 0
  safe_restart_enabled = 0
  event_rule_count     = 0

  capacity_notifications_arn = module.dublin_notifications.topic_arn
  devops_notifications_arn   = module.dublin_notifications.topic_arn
  notification_arn           = module.dublin_notifications.topic_arn

  auth_docker_image             = format("%s/authorisation-api:staging", local.docker_image_path)
  user_signup_docker_image      = ""
  logging_docker_image          = ""
  safe_restart_docker_image     = ""
  backup_rds_to_s3_docker_image = ""

  db_hostname = ""

  user_db_hostname = ""
  ## TODO This should depend on the resource
  user_rr_hostname = "users-rr.${lower(local.dublin_aws_region_name)}.${local.env_subdomain}.service.gov.uk"

  rack_env                = "staging"
  sentry_current_env      = "secondary-staging"
  radius_server_ips       = local.frontend_radius_ips
  subnet_ids              = module.dublin_backend.backend_subnet_ids
  private_subnet_ids      = module.dublin_backend.backend_private_subnet_ids
  nat_gateway_elastic_ips = module.dublin_backend.nat_gateway_elastic_ips
  rds_mysql_backup_bucket = module.dublin_backend.rds_mysql_backup_bucket

  admin_app_data_s3_bucket_name = module.london_admin.app_data_s3_bucket_name

  backend_sg_list = [
    module.dublin_backend.be_admin_in,
  ]

  low_cpu_threshold = 0.3
}

module "dublin_route53_notifications" {
  providers = {
    aws = aws.us_east_1
  }

  source = "../../sns-notification"

  topic_name = "govwifi-staging-dublin"
  emails     = [var.notification_email]
}

module "dublin_notifications" {
  providers = {
    aws = aws.dublin
  }

  source = "../../sns-notification"

  topic_name = "govwifi-staging"
  emails     = [var.notification_email]
}