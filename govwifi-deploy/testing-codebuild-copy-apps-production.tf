resource "aws_codebuild_project" "testing_codebuild_copy_push_app_production" {
  name          = "TESTING-copy-push-image-to-ecr-PRODUCTION"
  description   = "A common project that Copies the docker app image from STAGInG and pushes to PROD ECR"
  build_timeout = "20"
  service_role  = aws_iam_role.govwifi_codebuild.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  cache {
    type     = "S3"
    location = aws_s3_bucket.codepipeline_bucket.bucket
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:7.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = local.aws_account_id
    }

    environment_variable {
      name  = "AWS_REGION"
      value = "eu-west-2"
    }

    environment_variable {
      name  = "DOCKER_HUB_AUTHTOKEN_ENV"
      value = "/govwifi-cd/pipelines/main/docker_hub_authtoken"
      type  = "PARAMETER_STORE"
    }

    environment_variable {
      name  = "DOCKER_HUB_USERNAME_ENV"
      value = "/govwifi-cd/pipelines/main/docker_hub_username"
      type  = "PARAMETER_STORE"
    }

  }

  logs_config {
    cloudwatch_logs {
      group_name  = "govwifi-codebuild-push-image-to-ecr-log-group"
      stream_name = "govwifi-codebuild-push-image-to-ecr-log-stream"
    }

    s3_logs {
      status   = "ENABLED"
      location = "${aws_s3_bucket.codepipeline_bucket.id}/build-log"
    }
  }

  source {
    type      = "NO_SOURCE"
    buildspec = file("${path.module}/buildspec_production_deployed_image.yml")
  }
}
