variable "aws_region" {
}

variable "env" {
}

variable "aws_account_id" {
}

variable "region_name" {
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
