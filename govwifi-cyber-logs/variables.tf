variable "shard_count" {
  type        = number
  default     = 3
  description = "The shard count of the kinesis stream - defaults to 1 but can be increased based on throughput."
}

variable "cribl_worker_arn" {
  type        = string
  default     = "arn:aws:iam::195936642447:role/main-gds-general"
  description = "The ARN of the Cribl worker - this will be provided by the Cyber Engineering team."
}

variable "env" {
  type        = string
  description = "The environment to be deployed to (development, staging, prod)"

  validation {
    condition     = contains(["development", "staging", "prod"], var.env)
    error_message = "Environment must be one of: development, staging or prod"
  }
}

variable "region" {
  type    = string
  default = "eu-west-2"
}

variable "aws_account_id" {
  type        = string
  description = "The AWS account ID where the resources will be deployed."
}