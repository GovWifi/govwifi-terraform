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
    image                       = "aws/codebuild/standard:8.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true

    environment_variable {
      name  = "CERT_NOTIFICATION_TOPIC_ARN"
      value = aws_sns_topic.cert_notifications.arn
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

resource "aws_cloudwatch_event_target" "trigger_renew_certs" {
  rule = aws_cloudwatch_event_rule.renew_certs_schedule_rule.name
  arn  = aws_codebuild_project.renew_certs.id

  role_arn = "arn:aws:iam::${var.aws_account_id}:role/govwifi-codebuild-role"
}

# Enable check for expired certificates every evening at midnight, UTC 
resource "aws_cloudwatch_event_rule" "renew_certs_schedule_rule" {
  name                = "renew-certs-scheduled-build"
  schedule_expression = "cron(0 0 ? * MON-FRI *)"
}
