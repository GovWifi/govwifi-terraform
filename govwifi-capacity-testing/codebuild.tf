resource "aws_codebuild_project" "docker_capacity_testing_ecr" {
  name          = "govwifi-docker-capacity-testing-to-ecr"
  description   = "Builds and pushes docker-capacity-testing image to ECR"
  build_timeout = "30"
  service_role  = aws_iam_role.govwifi_capacity_test.arn

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
      name  = "AWS_ACCOUNT_ID"
      value = var.aws_account_id
    }

    environment_variable {
      name  = "ECR_REPOSITORY_URI"
      value = aws_ecr_repository.capacity_testing.repository_url
    }

    environment_variable {
      name  = "AWS_REGION"
      value = "eu-west-2"
    }

    environment_variable {
      name  = "DOCKER_HUB_AUTHTOKEN_ENV"
      value = "/govwifi/capacity_testing/docker_hub_authtoken"
      type  = "PARAMETER_STORE"
    }

    environment_variable {
      name  = "DOCKER_HUB_USERNAME_ENV"
      value = "/govwifi/capacity_testing/docker_hub_username"
      type  = "PARAMETER_STORE"
    }

  }

  source {
    type            = "GITHUB"
    location        = "https://github.com/GovWifi/govwifi-docker-radius-tools.git"
    git_clone_depth = 1
    buildspec       = <<-EOT
      version: 0.2
      phases:
        pre_build:
          commands:
            - echo Logging in to Amazon ECR...
            - echo "$DOCKER_HUB_AUTHTOKEN_ENV" | docker login -u $(echo $DOCKER_HUB_USERNAME_ENV) --password-stdin
            - REPOSITORY_NAME=$(echo $ECR_REPOSITORY_URI | cut -d'/' -f2)
            - IMAGE_TAG="latest"
        build:
          commands:
            - echo Building the Docker image on `date`
            - docker build -t $ECR_REPOSITORY_URI:$IMAGE_TAG .
            - docker tag $ECR_REPOSITORY_URI:$IMAGE_TAG $ECR_REPOSITORY_URI:latest
        post_build:
          commands:
            - aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
            - echo Pushing the Docker image to ECR on `date`
            - docker push $ECR_REPOSITORY_URI:$IMAGE_TAG
            - echo Writing image definitions file...
            - printf '[{"name":"capacity-testing","imageUri":"%s"}]' $ECR_REPOSITORY_URI:$IMAGE_TAG > imagedefinitions.json
      artifacts:
        files: imagedefinitions.json
    EOT
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "govwifi-docker-capacity-testing-group"
      stream_name = "govwifi-docker-capacity-testing-stream"
    }

    s3_logs {
      status   = "ENABLED"
      location = "${aws_s3_bucket.codebuild_logs_bucket.id}/capacity-tests-codebuild-logs"
    }
  }

}
