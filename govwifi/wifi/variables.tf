variable "ssh_key_name" {
  type    = string
  default = "govwifi-bastion-key"
}

# Entries below should probably stay as is for different environments
#####################################################################
variable "aws_region" {
  type    = string
  default = "eu-west-1"
}

variable "aws_region_name" {
  type    = string
  default = "Dublin"
}

variable "backup_region_name" {
  type    = string
  default = "London"
}

variable "ami" {
  # eu-west-1, Amazon Linux AMI 2.0.20210819 x86_64 ECS HVM GP2
  default     = "ami-0edfed61b9e44e914"
  description = "AMI id to launch, must be in the region specified by the region variable"
}

# Secrets

variable "london_radius_ip_addresses" {
  type        = list(string)
  description = "Frontend RADIUS server IP addresses - London"
}

variable "dublin_radius_ip_addresses" {
  type        = list(string)
  description = "Frontend RADIUS server IP addresses - Dublin"
}

variable "london_api_base_url" {
  type        = string
  description = "Base URL for authentication, user signup and logging APIs"
  default     = "https://api-elb.london.wifi.service.gov.uk:8443"
}

variable "dublin_api_base_url" {
  type        = string
  description = "Dublin - base URL for authentication, user signup and logging APIs"
  default     = "https://api-elb.dublin.wifi.service.gov.uk:8443"
}

variable "user_db_hostname" {
  type        = string
  description = "User details database hostname"
  default     = "users-db.london.production.wifi.service.gov.uk"
}

variable "user_rr_hostname" {
  type        = string
  description = "User details read replica hostname"
  default     = "users-rr.dublin.production.wifi.service.gov.uk"
}

variable "critical_notification_email" {
  type = string
}

variable "capacity_notification_email" {
  type = string
}

variable "devops_notification_email" {
  type = string
}

variable "prometheus_ip_london" {
}

variable "prometheus_ip_ireland" {
}

variable "grafana_ip" {
}
