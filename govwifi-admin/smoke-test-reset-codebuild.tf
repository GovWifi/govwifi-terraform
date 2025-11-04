resource "aws_codebuild_project" "govwifi_codebuild_project_reset-smoke-tests" {
  name          = "govwifi-reset-smoke-tests"
  description   = "Force reset of the smoke tests"
  build_timeout = "30"
  service_role  = aws_iam_role.govwifi_codebuild.arn

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
      value = aws_ecs_cluster.admin_cluster.name
    }
    environment_variable {
      name  = "SECURITY_GROUPS"
      value = "'${aws_security_group.admin_ec2_in.id}','${aws_security_group.admin_ec2_out.id}'"

    }
    environment_variable {
      name  = "CONTAINER_NAME"
      value = "admin"
    }

    environment_variable {
      name  = "TASK_DEF"
      value = aws_ecs_task_definition.admin_task.family
    }

    environment_variable {
      name  = "RAKE_TASK_NAME"
      value = "smoke_tests_reset"
    }

environment_variable {
      name  = "GW_USER"
      value = "deploy/gw_user"
      type  = "SECRETS_MANAGER"
    }

    environment_variable {
      name  = "GW_PASS"
      value = "deploy/gw_pass"
      type  = "SECRETS_MANAGER"
    }

    environment_variable {
      name  = "GW_SUPER_ADMIN_USER"
      value = "deploy/gw_super_admin_user"
      type  = "SECRETS_MANAGER"
    }

    environment_variable {
      name  = "GW_SUPER_ADMIN_PASS"
      value = "deploy/gw_super_admin_pass"
      type  = "SECRETS_MANAGER"
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
    buildspec = file("${path.module}/smoke-test-reset-buildspec.yml")
  }
}
