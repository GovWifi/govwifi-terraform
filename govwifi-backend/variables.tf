variable "env_name" {
  type = string
}

variable "env" {
  type = string
}

variable "env_subdomain" {
  type = string
}

variable "route53_zone_id" {
}

variable "vpc_cidr_block" {
}

variable "aws_account_id" {
  type = number
}

variable "aws_region" {
  type = string
}

variable "aws_region_name" {
  type = string
}

variable "administrator_cidrs" {
}

variable "frontend_radius_ips" {
}

variable "enable_bastion" {
  type    = number
  default = 1
}

variable "bastion_instance_type" {
  type = string
}

variable "bastion_server_ip" {
  default = null
}

variable "bastion_ssh_key_name" {
  type = string
}

variable "user_db_hostname" {
  type = string
}

variable "user_rr_hostname" {
  type = string
}

variable "db_instance_count" {
  type = number
}

variable "db_replica_count" {
  type = number
}

variable "user_db_replica_count" {
  type    = number
  default = 0
}

variable "db_backup_retention_days" {
  type = number
}

variable "db_encrypt_at_rest" {
}

variable "user_db_instance_type" {
  type = string
}

variable "db_monitoring_interval" {
}

variable "session_db_instance_type" {
  type = string
}

variable "session_db_storage_gb" {
  description = "The amount of storage to allocate to the db"
  type        = number
}

variable "user_db_storage_gb" {
  type = number
}

variable "db_maintenance_window" {
  type = string
}

variable "db_backup_window" {
  type = string
}

variable "rr_instance_type" {
  type = string
}

variable "rr_storage_gb" {
  type = number
}

variable "user_rr_instance_type" {
  default = "db.t3.medium"
}

variable "critical_notifications_arn" {
  type = string
}

variable "capacity_notifications_arn" {
  type = string
}

variable "enable_bastion_monitoring" {
  type = bool
}

variable "user_replica_source_db" {
  type    = string
  default = ""
}

variable "prometheus_ip_london" {
}

variable "prometheus_ip_ireland" {
}

variable "grafana_ip" {
}

variable "backup_mysql_rds" {
  description = "Whether or not to create objects to and make backups of MySQL RDS data"
  default     = false
  type        = bool
}

variable "db_storage_alarm_threshold" {
  description = "DB storage threshold used for alarms. Value varies based on environment and storage average."
  type        = number
}

variable "recovery_backups_enabled" {
}
