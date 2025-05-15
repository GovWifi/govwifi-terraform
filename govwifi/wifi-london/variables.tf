variable "ssh_key_name" {
  type    = string
  default = "govwifi-key-20180530"
}

# Entries below should probably stay as is for different environments
#####################################################################
variable "aws_region" {
  type    = string
  default = "eu-west-2"
}

variable "aws_region_name" {
  type    = string
  default = "London"
}

variable "backup_region_name" {
  type    = string
  default = "Dublin"
}

variable "ami" {
  # eu-west-2, Amazon Linux AMI 2.0.20210819 x86_64 ECS HVM GP2
  default     = "ami-0820c1f2c6fc9dff1"
  description = "AMI id to launch, must be in the region specified by the region variable"
}

# Secrets

variable "public_google_api_key" {
  type    = string
  default = "AIzaSyCz1cPYKamsA_ZJCygL9EY0Zq6stkazTco"
}

variable "user_db_hostname" {
  type        = string
  description = "User details database hostname"
  default     = "users-db.london.production.wifi.service.gov.uk"
}

variable "user_rr_hostname" {
  type        = string
  description = "User details read replica hostname"
  default     = "users-rr.london.production.wifi.service.gov.uk"
}

variable "zendesk_api_user" {
  type        = string
  description = "User for authenticating with Zendesk API"
}

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

variable "notify_ips" {
}

variable "smoketests_vpc_cidr" {
}

variable "smoketest_subnet_private_a" {
}

variable "smoketest_subnet_private_b" {
}

variable "smoketest_subnet_public_a" {
}

variable "smoketest_subnet_public_b" {
}
