resource "aws_codebuild_project" "smoke_tests" {
  name          = "govwifi-smoke-tests"
  description   = "This project runs the govwifi tests at regular intervals"
  build_timeout = "15"
  service_role  = aws_iam_role.govwifi_codebuild.arn

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
      name  = "BRANCH"
      value = "main"
    }

    environment_variable {
      name  = "REPO_NAME"
      value = var.smoke_tests_repo_name
    }

    environment_variable {
      name  = "DOCKER_HUB_AUTHTOKEN_ENV"
      value = data.aws_secretsmanager_secret_version.docker_hub_authtoken.secret_string
    }

    environment_variable {
      name  = "DOCKER_HUB_USERNAME_ENV"
      value = data.aws_secretsmanager_secret_version.docker_hub_username.secret_string
    }

    environment_variable {
      name  = "GW_USER"
      value = data.aws_secretsmanager_secret_version.gw_user.secret_string
    }

    environment_variable {
      name  = "GW_PASS"
      value = data.aws_secretsmanager_secret_version.gw_pass.secret_string
    }

    environment_variable {
      name  = "GW_2FA_SECRET"
      value = data.aws_secretsmanager_secret_version.gw_2fa_secret.secret_string
    }

    environment_variable {
      name  = "GW_SUPER_ADMIN_USER"
      value = data.aws_secretsmanager_secret_version.gw_super_admin_user.secret_string
    }

    environment_variable {
      name  = "GW_SUPER_ADMIN_PASS"
      value = data.aws_secretsmanager_secret_version.gw_super_admin_pass.secret_string
    }

    environment_variable {
      name  = "GW_SUPER_ADMIN_2FA_SECRET"
      value = data.aws_secretsmanager_secret_version.gw_super_admin_2fa_secret.secret_string
    }


    environment_variable {
      name  = "GOOGLE_API_CREDENTIALS"
      value = data.aws_secretsmanager_secret_version.google_api_credentials.secret_string
    }

    environment_variable {
      name  = "GOOGLE_API_TOKEN_DATA"
      value = data.aws_secretsmanager_secret_version.google_api_token_data.secret_string
    }


    environment_variable {
      name  = "RADIUS_KEY"
      value = data.aws_secretsmanager_secret_version.radius_key.secret_string
    }

    environment_variable {
      name  = "RADIUS_IPS"
      value = "${data.aws_secretsmanager_secret_version.radius_ips_dublin.secret_string},${data.aws_secretsmanager_secret_version.radius_ips_london.secret_string}"
    }

    environment_variable {
      name  = "SUBDOMAIN"
      value = var.env_subdomain
    }

    environment_variable {
      name  = "GOVWIFI_PHONE_NUMBER"
      value = var.govwifi_phone_number
    }

    environment_variable {
      name  = "SMOKETEST_PHONE_NUMBER"
      value = local.smoketest_phone_number
    }

    environment_variable {
      name  = "NOTIFY_GO_TEMPLATE_ID"
      value = local.notify_go_template_id
    }

    environment_variable {
      name  = "NOTIFY_SMOKETEST_API_KEY"
      value = data.aws_secretsmanager_secret_version.notify_smoketest_api_key.secret_string
    }

    environment_variable {
      name  = "NOTIFY_FIELD"
      value = var.notify_field
    }

    environment_variable {
      name  = "EAP_TLS_CLIENT_CERT"
      value = data.aws_secretsmanager_secret_version.eap_tls_client_cert.secret_string
    }

    environment_variable {
      name  = "EAP_TLS_CLIENT_KEY"
      value = data.aws_secretsmanager_secret_version.eap_tls_client_key.secret_string
    }

    environment_variable {
      name  = "ENVIRONMENT"
      value = var.environment
    }

  }

  source {
    type      = "NO_SOURCE"
    buildspec = file("${path.module}/buildspec.yml")

  }

  vpc_config {
    vpc_id = var.vpc_id

    # IDs of the two PRIVATE subnets
    subnets = [
      "${var.smoketest_subnet_private_a}",
      "${var.smoketest_subnet_private_b}",
    ] #

    security_group_ids = [
      "${var.default_security_group_id}"
    ] #The default vpc security group goes here. Lets all traffic in and out (this is what all the codebuild jobs do anyway)
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "govwifi-smoke-tests-group"
      stream_name = "govwifi-smoke-tests-stream"
    }

    s3_logs {
      status   = "ENABLED"
      location = "${aws_s3_bucket.smoke_tests_bucket.id}/smoke-tests-log"
    }
  }

}

# Trigger smoke-tests every 15 minutes
resource "aws_cloudwatch_event_target" "trigger_smoke_tests" {
  rule = aws_cloudwatch_event_rule.smoke_tests_schedule_rule.name
  arn  = aws_codebuild_project.smoke_tests.id

  role_arn = aws_iam_role.govwifi_codebuild.arn
}

# Enable scheduled smoke tests in production environment only
resource "aws_cloudwatch_event_rule" "smoke_tests_schedule_rule" {
  state               = var.env == "wifi" ? "ENABLED" : "DISABLED"
  name                = "smoke-tests-scheduled-build"
  schedule_expression = "cron(0/15 * * * ? *)"
}
