variable "env_name" {
}

variable "env_subdomain" {
}

variable "route53_zone_id" {
}

variable "vpc_cidr_block" {
}

variable "aws_region" {
}

variable "aws_region_name" {
}

variable "radius_instance_count" {
}

variable "frontend_docker_image" {
}

variable "raddb_docker_image" {
}

variable "ami" {
  description = "AMI id to launch, must be in the region specified by the region variable"
}

variable "ssh_key_name" {
}

variable "dns_numbering_base" {
}

variable "logging_api_base_url" {
}

variable "auth_api_base_url" {
}

variable "enable_detailed_monitoring" {
}

variable "radiusd_params" {
  default = "-f"
}

variable "rack_env" {
  default = ""
}

variable "sentry_current_env" {
  description = "The environment that Sentry will log errors to: e.g. staging"
}

variable "create_ecr" {
  description = "Whether or not to create ECR repository"
  default     = 0
}

variable "bastion_server_ip" {
}

variable "critical_notifications_arn" {
  type = string
}

variable "us_east_1_critical_notifications_arn" {
  type = string
}

variable "us_east_1_pagerduty_notifications_arn" {
  type = string
}

variable "admin_app_data_s3_bucket_name" {
  type = string
}

variable "radius_cidr_blocks" {
  description = "IP addresses for the London and Ireland Radius instances in CIDR block format"
  type        = list(string)
}

variable "prometheus_ip_london" {
}

variable "prometheus_ip_ireland" {
}

variable "is_production_aws_account" {
  default = true
}
