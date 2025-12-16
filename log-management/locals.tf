locals {
  ## Define log groups for different applications
  ## format "short app/api/group reference name" = "full log group name"
  log_groups = {
    "admin" = "${var.env_name}-admin-log-group",
  }
}
