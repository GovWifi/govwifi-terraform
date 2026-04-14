resource "aws_codebuild_project" "govwifi_codebuild_acceptance_tests" {
  name           = "acceptance-tests"
  description    = "This project runs the frontend acceptance tests"
  build_timeout  = "20"
  service_role   = aws_iam_role.govwifi_codebuild.arn
  encryption_key = aws_kms_key.codepipeline_key.arn

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
      name  = "DOCKER_HUB_AUTHTOKEN_ENV"
      value = data.aws_secretsmanager_secret_version.docker_hub_authtoken.secret_string
    }

    environment_variable {
      name  = "DOCKER_HUB_USERNAME_ENV"
      value = data.aws_secretsmanager_secret_version.docker_hub_username.secret_string
    }

    ## Use this to over ride the branch.
    environment_variable {
      name  = "BRANCH"
      value = "master"
    }

    ## if testing branches other than main/master, change these to match the branch name.
    environment_variable {
      name  = "FRONTEND_BRANCH"
      value = "master"
    }

    environment_variable {
      name  = "AUTH_API_BRANCH"
      value = "master"
    }

    environment_variable {
      name  = "LOGGING_API_BRANCH"
      value = "master"
    }

    environment_variable {
      name  = "USER_SIGNUP_API_BRANCH"
      value = "master"
    }

    environment_variable {
      name  = "ADMIN_BRANCH"
      value = "master"
    }
  }

  source {
    type      = "NO_SOURCE"
    buildspec = file("${path.module}/buildspec_acceptance_tests.yml")
  }


  logs_config {
    cloudwatch_logs {
      group_name  = "govwifi-acceptance-tests-group"
      stream_name = "govwifi-acceptance-tests-stream"
    }

    s3_logs {
      status   = "ENABLED"
      location = "${aws_s3_bucket.codepipeline_bucket.id}/acceptance-tests-log"
    }
  }

}
