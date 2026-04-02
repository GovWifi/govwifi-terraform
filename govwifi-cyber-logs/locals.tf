locals {
  aws_account_id = data.aws_caller_identity.current.account_id
  ## Define log groups for different applications
  ## format "short app/api/group reference name" = "full log group name"
  london_log_groups = {
    "admin"              = "${var.env}-admin-log-group",
    "authentication-api" = "${var.env}-authentication-api-docker-log-group",
    "logging-api"        = "${var.env}-logging-api-docker-log-group",
    "user-signup-api"    = "${var.env}-user-signup-api-docker-log-group",
    "radius-docker"      = "${var.env}-frontend-docker-log-group",
    "radius"             = "frontend"
  }
  ireland_log_groups = {
    "authentication-api" = "${var.env}-authentication-api-docker-log-group",
    "radius-docker"      = "${var.env}-frontend-docker-log-group",
    "radius"             = "frontend"
  }
  # If region is London, use London list. Otherwise use Ireland.
  log_groups = var.region == "eu-west-2" ? local.london_log_groups : local.ireland_log_groups
}