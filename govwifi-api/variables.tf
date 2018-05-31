variable "Env-Name" {}

variable "Env-Subdomain" {}

variable "route53-zone-id" {}

variable "aws-region" {}

variable "aws-region-name" {}

variable "ami" {
  description = "AMI id to launch, must be in the region specified by the region variable"
}

variable "ssh-key-name" {}

variable "backend-instance-count" {}

variable "backend-min-size" {}

variable "backend-cpualarm-count" {}

variable "backend-elb-count" {}

variable "aws-account-id" {}

variable "elb-ssl-cert-arn" {}

variable "db-user" {}

variable "db-password" {}

variable "radius-server-ips" {}

variable "shared-key" {}

variable "elb-sg-list" {
  type = "list"
}

variable "backend-sg-list" {
  type = "list"
}

variable "critical-notifications-arn" {}

variable "capacity-notifications-arn" {}

variable "users" {
  type = "list"
}

variable "zone-names" {
  type = "map"
}

variable "subnet-ids" {
  type = "list"
}

variable "ecs-instance-profile-id" {}
variable "ecs-service-role" {}

variable "health_check_grace_period" {
  default     = "300"
  description = "Time after instance comes into service before checking health"
}

# Service-specific settings
variable "clients-docker-image" {}
variable "auth-docker-image" {}
