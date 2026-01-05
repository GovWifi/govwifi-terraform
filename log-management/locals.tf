locals {
  ## Define log groups for different applications
  ## format "short app/api/group reference name" = "full log group name"
  log_groups = {
    "admin"              = "${var.env_name}-admin-log-group",
    "authentication-api" = "${var.env_name}-authentication-api-docker-log-group"
    #    "logging-api" = "${var.env_name}-logging-api-docker-log-group",
    #    "user-signup-api" = "${var.env_name}-user-signup-api-docker-log-group",
    #    "radius-docker" = "${var.env_name}-frontend-docker-log-group",
    #    "radius-certs" = "frontend",
    #    "prometheus" = "${var.env_name}-prometheus-log-group"
    #    "grafana" = "${var.env_name}-grafana-log-group"
  }
}
