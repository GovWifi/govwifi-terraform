resource "aws_cloudwatch_log_metric_filter" "auth_shared_secret_incorrect" {
  name = "${var.env_name}-auth-shared-secret-incorrect"

  pattern        = "\"Shared secret is incorrect\" \"Received packet\""
  log_group_name = aws_cloudwatch_log_group.frontend.name

  metric_transformation {
    name          = "auth-shared-secret-incorrect-count"
    namespace     = local.frontend_metrics_namespace
    value         = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_log_metric_filter" "accounting_shared_secret_incorrect" {
  name = "${var.env_name}-accounting-shared-secret-incorrect"

  pattern        = "\"Shared secret is incorrect\" \"Received Accounting-Request packet\""
  log_group_name = aws_cloudwatch_log_group.frontend.name

  metric_transformation {
    name          = "accounting-shared-secret-incorrect-count"
    namespace     = local.frontend_metrics_namespace
    value         = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_log_metric_filter" "outer_and_inner_identities_same" {
  name = "${var.env_name}-outer-and-inner-identities-same"

  pattern        = "\"Outer and inner identities are the same\""
  log_group_name = aws_cloudwatch_log_group.frontend.name

  metric_transformation {
    name          = "outer-and-inner-identities-same-count"
    namespace     = local.frontend_metrics_namespace
    value         = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_log_metric_filter" "unknown_client" {
  name = "${var.env_name}-unknown-client"

  pattern        = "\"unknown client\""
  log_group_name = aws_cloudwatch_log_group.frontend.name

  metric_transformation {
    name          = "unknown-client"
    namespace     = local.frontend_metrics_namespace
    value         = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_log_metric_filter" "radius_cannot_connect_to_api" {
  name = "${var.env_name}-radius-cannot-connect-to-api"

  pattern        = "\"ERROR: Server returned no data\""
  log_group_name = aws_cloudwatch_log_group.frontend.name

  metric_transformation {
    name          = "radius-cannot-connect-to-api"
    namespace     = local.frontend_metrics_namespace
    value         = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_log_metric_filter" "eap_too_many_sessions" {
  name           = "${var.env_name}-eap-max-open-sessions"
  log_group_name = aws_cloudwatch_log_group.frontend.name
  pattern        = "Too many open sessions"
  metric_transformation {
    name          = "eap-max-open-sessions"
    namespace     = local.frontend_metrics_namespace
    value         = 1
    default_value = 0
  }
}
