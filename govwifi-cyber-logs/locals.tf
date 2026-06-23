locals {
  aws_account_id = data.aws_caller_identity.current.account_id
  ## Define log groups for different applications
  ## format "short app/api/group reference name" = "full log group name"
  london_log_groups = {
    "admin"              = "${var.env_name}-admin-log-group",
    "authentication-api" = "${var.env_name}-authentication-api-docker-log-group",
    "logging-api"        = "${var.env_name}-logging-api-docker-log-group",
    "user-signup-api"    = "${var.env_name}-user-signup-api-docker-log-group",
    "radius-docker"      = "${var.env_name}-frontend-docker-log-group",
    "radius"             = "frontend"
  }
  ireland_log_groups = {
    "authentication-api" = "${var.env_name}-authentication-api-docker-log-group",
    "radius-docker"      = "${var.env_name}-frontend-docker-log-group",
    "radius"             = "frontend"
  }
  # If region is London, use London list. Otherwise use Ireland.
  log_groups = var.region == "eu-west-2" ? local.london_log_groups : local.ireland_log_groups
}