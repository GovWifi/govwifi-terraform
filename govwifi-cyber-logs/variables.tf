variable "shard_count" {
  type        = number
  default     = 1
  description = "The shard count of the kinesis stream - defaults to 1 but can be increased based on throughput."
}

variable "cribl_worker_arn" {
  type        = string
  default     = "arn:aws:iam::195936642447:role/main-gds-general"
  description = "The ARN of the Cribl worker - this will be provided by the Cyber Engineering team."
}

variable "account_access_arns" {
  type        = list(string)
  description = "A list of all account ARNs that need to send logs to kinesis stream (note - include the account containing the kinesis stream). The format is (arn:aws:logs:eu-west-2:account_number:*)"
  default = ["arn:aws:logs:eu-west-2:269352317959:*"]
}

variable "env" {
  type = string
  description = "The environment to be deployed to (development, staging, prod)"

  validation {
    condition     = contains(["development", "staging", "prod"], var.env)
    error_message = "Environment must be one of: development, staging or prod"
  }
}

variable "region" {
  type = string
  default = "eu-west-2"
}

# variable "aws_account_sources" {
#   description = "A list of all AWS accounts that will send logs to kinesis stream (note - include the account containing the kinesis stream). Only the 12 digit account numbers are required"
#   default = []
# }