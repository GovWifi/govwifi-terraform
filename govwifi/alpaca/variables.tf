variable "ssh_key_name" {
  type    = string
  default = "govwifi-alpaca-ec2-instances-key-20230822"
}

variable "ssh_key_name_pub" {
  type    = string
  default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC4q8NhyH2wtEj8CiqOn+4OFgrB6wZgdzB/qjEh1t7ATQwgkFii0vtsJIzTfOVyxLr0rF79TQCdy7RcVidnZJOoa6QYJRDUx61f2bSacDsiI04/6QSAzqYe0x12fDoRMZqU6GWN1tRY3HYGdLCSMo8QaYonpdiyuS2q+gzFl1V1pk2c3/VT0KhZMWPV1qh6y6uCV13CkiFEgRpqhWTxfagv38lCRFvgJVmNxXtwBME8lqAs7DRoxfD5WZ4oGWO+wCaw+3QgD6gGDMUxpLk1CtL0BVpZ73OGB1XW2atTf2Ugma1jLMvP5IIrEDhMfOEX4iFexRVZBTqIqmsFaHjTH6BRp0J5FJ4suDVIv9eMblgZEGomDmP/T3ZIUq+96Z5BcOLpW1dEdCswbXtzuw7F+hIceSbnYMefSJ/8mhjxTcvBrJK4pv/BKEx/1UBOYtcwu3PZ52oiQaFFxElJiFTa/SUTLAks50e90o7kIZo2z4eal2e5mvWLSNwjA5kCniATfTs= govwifi-developers@digital.cabinet-office.gov.uk"
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
