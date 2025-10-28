variable "aws_account_id" {
}

variable "env" {
}

variable "env_subdomain" {
}

variable "smoketest_subnet_private_a" {
}

variable "smoketest_subnet_private_b" {
}

variable "create_slack_alert" {
}

variable "govwifi_phone_number" {
}

variable "notify_field" {
}

variable "smoke_tests_repo_name" {
}

variable "vpc_id" {
}

variable "default_security_group_id" {
}

variable "environment" {
}

variable "aws_security_group_admin_db_in" {
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for the Lambda function"
  type        = list(string)
  # Example default, replace with your actual subnet IDs
  # default     = ["subnet-0123456", "subnet-abcdefg"]
}

variable "backend_vpc_id" {
  description = "The VPC ID where the backend resources are located"
  type        = string
  # Example default, replace with your actual VPC ID
  # default     = "vpc-0123456789abcdef0"
}
