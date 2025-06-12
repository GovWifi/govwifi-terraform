variable "env" {
}

variable "env_name" {
}

variable "env_subdomain" {
}

variable "route53_zone_id" {
}

variable "aws_region" {
}

variable "aws_region_name" {
}

variable "alarm_count" {
  default = 1
}

variable "event_rule_count" {
  default = 1
}

variable "backend_instance_count" {
}

variable "authentication_api_count" {
  default = 3
}

variable "backend_elb_count" {
}

variable "aws_account_id" {
}

variable "user_signup_enabled" {
  default = 1
}

variable "logging_enabled" {
  default = 1
}

variable "safe_restart_enabled" {
  default = 1
}

variable "user_db_hostname" {
}

variable "user_rr_hostname" {
}

variable "db_hostname" {
}

variable "rack_env" {
}

variable "sentry_current_env" {
}

variable "radius_server_ips" {
  type = list(string)
}

variable "critical_notifications_arn" {
}

variable "capacity_notifications_arn" {
}

variable "devops_notifications_arn" {
}

variable "pagerduty_notifications_arn" {
  description = "Notification ARN for alerts. In production alerts are sent to PagerDuty, but in staging alerts are sent to an email group."
  type        = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "user_signup_docker_image" {
}

variable "logging_docker_image" {
}

variable "safe_restart_docker_image" {
}

variable "backup_rds_to_s3_docker_image" {
}

variable "ecr_repository_count" {
  default     = 0
  description = "Whether or not to create ECR repository"
}

variable "create_wordlist_bucket" {
  type    = bool
  default = false
}

variable "wordlist_file_path" {
  default     = ""
  description = "The local path of the wordlist which gets uploaded to S3"
}

variable "vpc_id" {
}

variable "vpc_endpoints_security_group_id" {
}

variable "admin_app_data_s3_bucket_name" {
  default     = ""
  type        = string
  description = "Name of the admin S3 bucket"
}

variable "firetext_token" {
  type    = string
  default = ""
}

variable "user_signup_api_is_public" {
  default = 0
}

variable "metrics_bucket_name" {
  type        = string
  default     = ""
  description = "Name of the S3 bucket to write metrics into"
}

variable "export_data_bucket_name" {
  type        = string
  default     = ""
  description = "Name of the bucket we use to export data to data.gov.uk"
}

variable "backup_mysql_rds" {
  description = "Whether or not to create objects to and make backups of MySQL RDS data"
  default     = false
  type        = bool
}

variable "low_cpu_threshold" {
  description = "Low CPU threshold for ECS task alarms. This value is higher (1%) for production but lower (0.3%) for staging and is based on average CPU."
  type        = number
}

variable "rds_mysql_backup_bucket" {
}

variable "elasticsearch_endpoint" {
  type    = string
  default = ""
}

variable "nat_gateway_elastic_ips" {
  type    = list(string)
  default = []
}

variable "notify_ips" {
  type    = list(string)
  default = []
}

variable "alb_permitted_security_groups" {
  type = list(string)
}

variable "alb_permitted_cidr_blocks" {
  type    = list(string)
  default = []
}

variable "app_env" {
}

variable "smoke_test_ips" {
  type    = list(string)
  default = []
}

variable "log_retention" {
}
