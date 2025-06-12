variable "env_name" {
}

variable "env_subdomain" {
}

variable "env" {
}

variable "aws_account_id" {
}

variable "route53_zone_id" {
}

variable "vpc_cidr_block" {
}

variable "backend_vpc_id" {
}

variable "aws_region" {
}

variable "aws_region_name" {
}

variable "radius_instance_count" {
}

variable "radius_task_count" {
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

variable "authentication_api_internal_dns_name" {
}

variable "logging_api_internal_dns_name" {
}

variable "enable_detailed_monitoring" {
}

variable "trusted_certificates_key" {
  default = "trusted_certificates/certificates.zip"
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

variable "pagerduty_notifications_arn" {
  type = string
}

variable "critical_notifications_arn" {
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

variable "prometheus_security_group_id" {
  type = string
}

variable "london_backend_vpc_cidr" {
}
