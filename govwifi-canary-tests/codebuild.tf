resource "aws_codebuild_project" "canary_tests" {
  name          = "govwifi-canary-tests"
  description   = "This project runs the govwifi canary tests at regular intervals"
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
      value = var.canary_tests_repo_name
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
      name  = "RADIUS_KEY"
      value = data.aws_secretsmanager_secret_version.radius_key.secret_string
    }

    environment_variable {
      name  = "RADIUS_IPS"
      value = "${data.aws_secretsmanager_secret_version.radius_ips_dublin.secret_string},${data.aws_secretsmanager_secret_version.radius_ips_london.secret_string}"
    }

    environment_variable {
      name  = "EAP_TLS_CLIENT_CERT"
      value = data.aws_secretsmanager_secret_version.eap_tls_client_cert.secret_string
    }

    environment_variable {
      name  = "EAP_TLS_CLIENT_KEY"
      value = data.aws_secretsmanager_secret_version.eap_tls_client_key.secret_string
    }

  }

  source {
    type      = "NO_SOURCE"
    buildspec = file("${path.module}/buildspec.yml")

  }

  vpc_config {
    vpc_id = aws_vpc.smoke_tests.id

    # IDs of the two PRIVATE subnets
    subnets = [
      "${aws_subnet.smoke_tests_private_a.id}",
      "${aws_subnet.smoke_tests_private_b.id}",
    ] #

    security_group_ids = [
      "${aws_vpc.smoke_tests.default_security_group_id}"
    ] #The default vpc security group goes here. Lets all traffic in and out (this is what all the codebuild jobs do anyway)
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "govwifi-canary-tests-group"
      stream_name = "govwifi-canary-tests-stream"
    }

    s3_logs {
      status   = "ENABLED"
      location = "${aws_s3_bucket.canary_tests_bucket.id}/canary-tests-log"
    }
  }

}

# Trigger canary-tests every 15 minutes
resource "aws_cloudwatch_event_target" "trigger_canary_tests" {
  rule = aws_cloudwatch_event_rule.canary_tests_schedule_rule.name
  arn  = aws_codebuild_project.canary_tests.id

  role_arn = aws_iam_role.govwifi_codebuild.arn
}

# Enable scheduled canary tests in production environment only
resource "aws_cloudwatch_event_rule" "canary_tests_schedule_rule" {
  state          = var.env == "wifi" ? "ENABLED" : "DISABLED"
  name                = "canary-tests-scheduled-build"
  schedule_expression = "cron(0/15 * * * ? *)"
}
