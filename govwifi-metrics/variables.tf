variable "aws_region" {
  type = string
}

variable "env" {
  type = string
}

variable "aws_account_id" {
  type = string
}

variable "region_name" {
  type = string
}

variable "engine" {
  type        = string
  description = "The name of the database engine to be used for this DB cluster"
  default     = "aurora-postgresql"
}

variable "engine_version" {
  type        = string
  description = "The database engine version"
  default     = "17.7"
}

variable "database_name" {
  type        = string
  description = "Name for an automatically created database on cluster creation"
}

variable "min_capacity" {
  type        = number
  description = "Minimum capacity for an Aurora DB cluster in serverless v2 scaling configuration"
  default     = 0.5
}

variable "max_capacity" {
  type        = number
  description = "Maximum capacity for an Aurora DB cluster in serverless v2 scaling configuration"
  default     = 1.0
}

variable "instance_count" {
  type        = number
  description = "Number of instances to create in the cluster"
  default     = 1
}

variable "skip_final_snapshot" {
  type        = bool
  description = "Determines whether a final DB snapshot is created before the DB cluster is deleted"
  default     = false
}

variable "backend_subnet_ids" {
  type        = list(string)
  description = "List of backend subnet IDs"
  default     = []
}

variable "backend_vpc_id" {
  type        = string
  description = "The ID of the backend VPC"
  default     = ""
}

variable "backend_vpc_cidr_block" {
  type        = string
  description = "The CIDR block of the backend VPC"
  default     = ""
}

variable "tags" {
  type        = map(string)
  description = "A mapping of tags to assign to the resource"
  default     = {}
}

variable "env_name" {
  type        = string
  description = "E.g. wifi"
}

variable "env_subdomain" {
  type        = string
  description = "E.g. staging.wifi"
}

variable "log_retention" {
  type        = number
  description = "The number of days worth of logs to keep E.g. 7"
  default     = 7
}

variable "route53_zone_id" {
  type        = string
  description = "Route53 zone to use for the domain name"
}

variable "admin_sg_id" {
  type        = string
  description = "Security group ID of the admin service for ingress"
}

variable "api_sg_id" {
  type        = string
  description = "Security group ID of the api services for ingress"
}

variable "metrics_api_docker_image" {
  type        = string
  description = "Docker image for the metrics API"
}

variable "vpc_endpoints_security_group_id" {
  type        = string
  description = "Security group ID for VPC endpoints"
}
