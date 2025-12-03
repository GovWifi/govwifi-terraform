# TODO This should probably be managed by Terraform at some point
data "aws_route53_zone" "main" {
  name = "${local.env_subdomain}.service.gov.uk."
}

data "aws_caller_identity" "current" {}
