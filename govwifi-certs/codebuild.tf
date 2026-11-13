data "aws_ssm_parameter" "frontend_cert_bucket" {
  name = "/govwifi-terraform/frontend-certs-bucket"
}

resource "aws_cloudwatch_log_group" "renew_certs" {
  name              = "govwifi-renew-certs-group"
  retention_in_days = 90
}

resource "aws_codebuild_project" "renew_certs" {
  name          = "govwifi-renew-certs"
  description   = "This project renews the GovWifi certificate periodically"
  build_timeout = "15"
  service_role  = aws_iam_role.renew_certs.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:7.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true

    ## Use this to over ride the branch, unable to use the normal source method as accounts would need github access.

    environment_variable {
      name  = "DIGICERT_API_KEY"
      value = data.aws_secretsmanager_secret_version.digicert_api_key.secret_string
    }

    environment_variable {
      name  = "CSR_FILE"
      value = data.aws_secretsmanager_secret_version.csr_file.secret_string
    }

    environment_variable {
      name  = "ORDER_ID"
      value = data.aws_secretsmanager_secret_version.dev_order_id.secret_string
    }

   environment_variable {
      name  = "FRONTEND_CERT_BUCKET_LONDON"
      value = data.aws_ssm_parameter.frontend_cert_bucket.value
    }

  }

  source {
    type      = "NO_SOURCE"
    buildspec = file("${path.module}/buildspec.yml")

  }


  logs_config {
    cloudwatch_logs {
      group_name  = aws_cloudwatch_log_group.renew_certs.name
      stream_name = "govwifi-renew-certs-stream"
    }

    s3_logs {
      status   = "ENABLED"
      location = "${aws_s3_bucket.renew_certs_bucket.id}/renew-certs-log"
    }
  }

}

# Trigger renew-certs every month
# resource "aws_cloudwatch_event_target" "trigger_renew_certs" {
#   rule = aws_cloudwatch_event_rule.renew_certs_schedule_rule.name
#   arn  = aws_codebuild_project.renew_certs.id

#   role_arn = "arn:aws:iam::${var.aws_account_id}:role/govwifi-codebuild-role"
# }

# # Enable scheduled cert rotation every 40 days
# resource "aws_cloudwatch_event_rule" "renew_certs_schedule_rule" {
#   name                = "renew-certs-scheduled-build"
#   schedule_expression = "cron(0 0 */40 * *)"
# }
