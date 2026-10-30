variable "aws_region" {
  type        = string
  default     = "eu-west-2"
  description = "Target AWS Region for the test"
}
variable "parameter_prefix" {
  type        = string
  default     = "/dev/govwifi20/tf-layer-test"
  description = "SSM namespace prefix to keep cleanup easy"
}
