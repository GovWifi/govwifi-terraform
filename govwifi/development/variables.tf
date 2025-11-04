variable "ssh_key_name" {
  type    = string
  default = "govwifi-development-bastion-20250922"
}

variable "notify_ips" {
}

# Secrets

variable "public_google_api_key" {
  type    = string
  default = "xxxxxxxxxxxxxxxxxxxxx"
}

variable "zendesk_api_user" {
  type        = string
  description = "Username for authenticating with Zendesk API"
}

variable "notification_email" {
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
