resource "aws_codebuild_project" "govwifi_codebuild_built_app" {
  for_each       = toset(var.built_app_names)
  name           = "${each.key}-push-docker-image-to-staging-ECR"
  description    = "This project builds the ${each.key} image and pushes it to ECR"
  build_timeout  = "12"
  service_role   = aws_iam_role.govwifi_codebuild.arn
  encryption_key = aws_kms_key.codepipeline_key.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:5.0"
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
      name  = "STAGE"
      value = "staging"
    }

  }

  source_version = "master"

  source {
    type            = "GITHUB"
    location        = "https://github.com/alphagov/govwifi-${each.key}.git"
    git_clone_depth = 1
    buildspec       = "buildspec.yml"
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

resource "aws_codebuild_webhook" "govwifi_built_app_webhook_staging" {
  for_each     = toset(var.built_app_names)
  project_name = "${each.key}-push-docker-image-to-staging-ECR"

  build_type = "BUILD"

  filter_group {
    filter {
      type    = "EVENT"
      pattern = "PULL_REQUEST_MERGED"
    }
  }
  depends_on = [
    aws_codebuild_project.govwifi_codebuild_built_app
  ]
}
