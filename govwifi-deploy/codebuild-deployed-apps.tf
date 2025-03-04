resource "aws_codebuild_project" "govwifi_codebuild_deployed_app" {
  for_each       = toset(var.deployed_app_names)
  name           = "${each.key}-app-build-push-image-ECR"
  description    = "This project builds the ${each.key} app docker image and pushes it to ECR"
  build_timeout  = "20"
  service_role   = aws_iam_role.govwifi_codebuild.arn
  encryption_key = aws_kms_key.codepipeline_key.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:6.0"
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

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = local.aws_account_id
    }

    environment_variable {
      name  = "ACCEPTANCE_TESTS_PROJECT_NAME"
      value = aws_codebuild_project.govwifi_codebuild_acceptance_tests.name
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec.yml"
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "govwifi-codebuild-${each.key}-group"
      stream_name = "govwifi-codebuild-${each.key}-stream"
    }

    s3_logs {
      status   = "ENABLED"
      location = "${aws_s3_bucket.codepipeline_bucket.id}/${each.key}-log"
    }
  }

}
