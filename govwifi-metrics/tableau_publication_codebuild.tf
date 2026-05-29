resource "aws_codebuild_project" "tableau_data_source_publication" {
  name           = "tableau-data-source-publication"
  description    = "This publishes the metrics data source(s) to Tableau using the https://github.com/GovWifi/govwifi-metrics-data-publisher repo"
  service_role   = aws_iam_role.govwifi_codebuild.arn
  encryption_key = aws_kms_key.codepipeline_key.arn
  build_timeout  = "20"

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:7.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true

    environment_variable {
      name  = "BRANCH"
      value = var.metrics_data_publisher_repository_branch
    }

    environment_variable {
      name  = "METRICS_API_URL"
      value = "https://metrics.${var.env_subdomain}.service.gov.uk"
    }

    environment_variable {
      name  = "METRICS_API_KEY"
      value = data.aws_secretsmanager_secret_version.metrics_api_key_data.secret_string
    }

    environment_variable {
      name  = "TOKEN_NAME"
      value = "gowwifi/metrics-api/key"
    }

    environment_variable {
      name  = "TOKEN_VALUE"
      value = data.aws_secretsmanager_secret_version.metrics_api_key_data.secret_string
    }

    environment_variable {
      name  = "SITE_ID"
      value = data.aws_secretsmanager_secret_version.metrics_data_publisher_tableau_data.SITE_ID
    }

    environment_variable {
      name  = "SERVER_URL"
      value = data.aws_secretsmanager_secret_version.metrics_data_publisher_tableau_data.SERVER_URL
    }

    environment_variable {
      name  = "PROJECT_NAME"
      value = data.aws_secretsmanager_secret_version.metrics_data_publisher_tableau_data.PROJECT_NAME
    }
  }

  source {
    type            = "GITHUB"
    location        = var.metrics_data_publisher_repository
    git_clone_depth = 1
    buildspec       = "buildspec.yml"
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "govwifi-metrics-data-publisher-group"
      stream_name = "govwifi-metrics-data-publisher-stream"
    }

    s3_logs {
      status   = "ENABLED"
      location = "${aws_s3_bucket.tableau_publication_bucket.id}/metrics-data-publisher-log"
    }
  }

}

# Trigger metrics-data-publisher every 15 minutes
resource "aws_cloudwatch_event_target" "trigger_tableau_publication" {
  rule = aws_cloudwatch_event_rule.tableau_publication_schedule_rule.name
  arn  = aws_codebuild_project.tableau_publication.id

  # role_arn = var.govwifi_codebuild_role_arn
}

# Enable scheduled smoke tests in production environment only
resource "aws_cloudwatch_event_rule" "tableau_publication_schedule_rule" {
  state               = var.env == "wifi" ? "ENABLED" : "DISABLED"
  name                = "metrics-data-publisher-scheduled-build"
  schedule_expression = "cron(0/15 * * * ? *)"
}
