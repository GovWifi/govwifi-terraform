resource "aws_cloudwatch_log_group" "prometheus_log_group" {
  name              = "${var.env_name}-prometheus-log-group"
  retention_in_days = var.log_retention
}