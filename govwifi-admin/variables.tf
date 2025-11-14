variable "env_name" {
  description = "E.g. wifi"
}

variable "env_subdomain" {
  description = "E.g. staging.wifi"
}

variable "env" {
  description = "E.g. production"
}

variable "aws_region" {
  description = "E.g. eu-west-2"
}

variable "aws_region_name" {
  description = "E.g. London"
}

variable "subnet_ids" {
  description = "List of AWS subnet IDs to place the EC2 instances and ELB into"
  type        = list(string)
}

variable "ecr_repository_count" {
  description = "Whether or not to create ECR repository"
  default     = 0
}

variable "rails_env" {
  description = "the Ruby environment, E.g. production, development, test"
}


variable "sentry_current_env" {
  description = "The environment that Sentry will log errors to: e.g. staging"
}

variable "vpc_id" {
  description = "VPC ID used for placing the ALB into"
}

variable "vpc_endpoints_security_group_id" {
}

variable "route53_zone_id" {
  description = "Route53 zone to use for the domain name"
}

variable "route53_zone_arn" {
  description = "Route53 zone arn to use with shield"
}


variable "instance_count" {
  description = "Number of EC2 hosts and ECS containers to be running"
}

variable "admin_docker_image" {
  description = "Docker image URL pointing to the admin platform application"
}

variable "critical_notifications_arn" {
}

variable "capacity_notifications_arn" {
}

variable "pagerduty_notifications_arn" {
  description = "Notification ARN for alerts. In production alerts are sent to PagerDuty, but in staging alerts are sent to an email group."
  type        = string
}

variable "db_backup_retention_days" {
}

variable "db_encrypt_at_rest" {
}

variable "db_instance_type" {
}

variable "db_monitoring_interval" {
}

variable "db_storage_gb" {
}

variable "db_maintenance_window" {
}

variable "db_backup_window" {
}

variable "rds_monitoring_role" {
}

variable "london_radius_ip_addresses" {
  type = list(string)
}

variable "dublin_radius_ip_addresses" {
  type = list(string)
}

variable "logging_api_search_url" {
}

variable "rr_db_host" {
}

variable "rr_db_name" {
}

variable "app_env" {
}

variable "user_db_host" {
}

variable "user_db_name" {
}

variable "zendesk_api_endpoint" {
}

variable "zendesk_api_user" {
}

variable "public_google_api_key" {
}

variable "bastion_server_ip" {
}

variable "elasticsearch_endpoint" {
}

variable "frontend_cert_bucket" {
}

variable "trusted_certificates_key" {
}

variable "log_retention" {
}

variable "govwifi_codebuild_role_arn" {
}

variable "smoke_test_ips" {
  type    = list(string)
  default = []
}