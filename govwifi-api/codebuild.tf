resource "aws_codebuild_project" "govwifi_codebuild_project_reset_smoke_tests" {
  count     = var.logging_enabled
  name          = "govwifi-reset-smoke-tests"
  description   = "Force reset of the smoke tests"
  build_timeout = "30"
  service_role  = "arn:aws:iam::${var.aws_account_id}:role/govwifi-codebuild-role"

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:6.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true

    environment_variable {
      name  = "SUBNETS"
      value = "'${var.subnet_ids[0]}','${var.subnet_ids[1]}','${var.subnet_ids[2]}'"
    }

    environment_variable {
      name  = "CLUSTER"
      value = "${var.env_name}-api-cluster"
    }
    environment_variable {
      name  = "SECURITY_GROUPS"
      value = "'${aws_security_group.api_in.id}','${aws_security_group.api_out.id}'"

    }
    environment_variable {
      name  = "CONTAINER_NAME"
      value = "logging-api"
    }

    environment_variable {
      name  = "TASK_DEF"
      value = "logging-api-scheduled-task-${var.env_name}"
    }

    environment_variable {
      name  = "RAKE_TASK_NAME"
      value = "smoke_tests_cleanup"
    }

    environment_variable {
      name  = "AWS_REGION"
      value = var.aws_region
    }

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = var.aws_account_id
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "govwifi-codebuild-smoke-tests-reset-log-group"
      stream_name = "govwifi-codebuild-smoke-tests-reset-log-stream"
    }

    s3_logs {
      status = "DISABLED"
    }
  }

  source {
    type      = "NO_SOURCE"
    buildspec = file("${path.module}/smoke-test-clean-buildspec.yml")
  }
}
