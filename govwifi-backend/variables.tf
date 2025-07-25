variable "env_name" {
}

variable "env" {
}

variable "env_subdomain" {
}

variable "route53_zone_id" {
}

variable "vpc_cidr_block" {
}

variable "aws_account_id" {
}

variable "aws_region" {
}

variable "aws_region_name" {
}

variable "administrator_cidrs" {
}

variable "frontend_radius_ips" {
}

variable "enable_bastion" {
  default = 1
}

variable "bastion_instance_type" {
}

variable "bastion_server_ip" {
  default = null
}

variable "bastion_ssh_key_name" {
}

variable "user_db_hostname" {
}

variable "user_rr_hostname" {
}

variable "db_instance_count" {
}

variable "db_replica_count" {
}

variable "user_db_replica_count" {
  default = 0
}

variable "db_backup_retention_days" {
}

variable "db_encrypt_at_rest" {
}

variable "session_db_instance_type" {
}

variable "user_db_instance_type" {
}

variable "db_monitoring_interval" {
}

variable "session_db_storage_gb" {
}

variable "user_db_storage_gb" {
}

variable "db_maintenance_window" {
}

variable "db_backup_window" {
}

variable "rr_instance_type" {
}

variable "rr_storage_gb" {
}

variable "user_rr_instance_type" {
  default = "db.t3.medium"
}

variable "critical_notifications_arn" {
}

variable "capacity_notifications_arn" {
}

variable "enable_bastion_monitoring" {
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

variable "recovery_backups_enabled"{
}
