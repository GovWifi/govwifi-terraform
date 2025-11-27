resource "aws_codebuild_project" "govwifi_codebuild_project_reset-smoke-tests" {
  name          = "govwifi-smoke-test-reset"
  description   = "Force reset of the smoke test users passwords, login attempts and remove site IPs"
  build_timeout = "30"
  service_role  = var.govwifi_codebuild_role_arn

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
      name  = "SUBNETS"
      value = join(",", var.subnet_ids)
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
      value = "reset:smoke_test_users"
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

    environment_variable {
      name  = "SMOKE_TEST_IPS"
      value = join(",", var.smoke_test_ips)
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
