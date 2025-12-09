variable "env" {
  type = string
}

variable "env_name" {
  type = string
}

variable "env_subdomain" {
  type = string
}

variable "route53_zone_id" {
}

variable "aws_region" {
  type = string
}

variable "aws_region_name" {
  type = string
}

variable "alarm_count" {
  default = 1
}

variable "event_rule_count" {
  default = 1
}

variable "backend_instance_count" {
  type = number
}

variable "authentication_api_count" {
  default = 3
}

variable "backend_elb_count" {
  type = number
}

variable "aws_account_id" {
  type = string
}

variable "user_signup_enabled" {
  default = 1
  type    = number
}

variable "logging_enabled" {
  default = 1
  type    = number
}

variable "safe_restart_enabled" {
  default = 1
  type    = number
}

variable "user_db_hostname" {
  type = string
}

variable "db_read_replica_hostname" {
  description = "The read replica hostname to query for statistics from."
  type        = string
}

variable "user_rr_hostname" {
  type = string
}

variable "db_hostname" {
  type = string
}

variable "rack_env" {
  type = string
}

variable "sentry_current_env" {
  type = string
}

variable "radius_server_ips" {
  type = list(string)
}

variable "critical_notifications_arn" {
  type = string
}

variable "capacity_notifications_arn" {
  type = string
}

variable "devops_notifications_arn" {
  type = string
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
  type = string
}

variable "logging_docker_image" {
  type = string
}

variable "safe_restart_docker_image" {
  type = string
}

variable "backup_rds_to_s3_docker_image" {
  type = string
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
  type = string
}

variable "vpc_endpoints_security_group_id" {
  type = string
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
  type    = number
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
  type = string
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
  type = string
}

variable "smoke_test_ips" {
  type    = list(string)
  default = []
}

variable "log_retention" {
  type = number
}
