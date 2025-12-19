# Unless there is a default provided, all values are inherited from the main deployment file.
# Values can also be overwritten from the main deployment file.

variable "env_name" {
  description = "Environment name for the component."
  type        = string
}

variable "env_subdomain" {
  description = "E.g. grafana.staging.wifi"
}

variable "aws_region" {
  description = "AWS region for the component."
  type        = string
}

variable "aws_region_name" {
}

variable "ssh_key_name" {
  description = "The SSH key name to use."
  type        = string
}

variable "backend_subnet_ids" {
  description = "List of AWS subnet IDs to place the EC2 instances and ELB into."
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC ID used for the Application Load Balancer."
  type        = string
}

variable "route53_zone_id" {
  description = "ID of the Route53 zone to use"
  type        = string
}

variable "bastion_ip" {
  description = "The IP address of the bastion machine."
  type        = string
}

variable "prometheus_ips" {
  description = "The list of allowed prometheus servers to connect to the EC2 instances on 9090."
  type        = list(string)
  default     = []
}

variable "subnet_ids" {
  description = "List of AWS subnet IDs to place the EC2 instances and ELB into"
  type        = list(string)
}

variable "administrator_cidrs" {
  description = "IPs associated with the GDS/CDIO VPN to allow access"
}

variable "grafana_device_name" {
  description = "Name of Grafana Persistent Drive Device Name"
  type        = string
  default     = "/dev/xvdp"
}

variable "grafana_docker_version" {
  description = "Grafana Docker Version Number"
  type        = string
  default     = "11.5.2"
}

variable "capacity_notifications_arn" {
  description = "Arn of the capacity monitoring nofications sns topic"
  type        = string
}

variable "aws_account_id" {
  type = string
}

variable "vpc_be_cidr_block" {
  type = string
}

variable "log_retention" {
  type = number
}