resource "aws_codebuild_project" "govwifi_codebuild_project_restart_ecs_cluster" {
  for_each      = toset(var.deployed_app_names)
  name          = "govwifi-ecs-update-service-${each.key}"
  description   = "Force restart the service to pick up the latest production image."
  build_timeout = "30"
  service_role  = "arn:aws:iam::${var.aws_account_id}:role/govwifi-codebuild-role"

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    ## Using Lambda Compute instead of EC2, for speed and efficiency, but caution, only for non privileged builds, great for cli commands, not for Docker builds.
    ## Also note that there is also a hard limit of 15 minutes build time.
    compute_type = "BUILD_LAMBDA_1GB"
    type         = "LINUX_LAMBDA_CONTAINER"
    image        = "aws/codebuild/amazonlinux-x86_64-lambda-standard:python3.12"

    environment_variable {
      name  = "SERVICE_NAME"
      value = each.key == "admin" ? "admin-${var.env_name}" : "${each.key}-service-${var.env_name}"
    }

    environment_variable {
      name  = "CLUSTER_NAME"
      value = each.key == "admin" ? "${var.env_name}-admin-cluster" : "${var.env_name}-api-cluster"
    }

    # This is the Task Definition Family Name
    environment_variable {
      name  = "FAMILY_NAME"
      value = "${each.key}-task-${var.env_name}"
    }

    environment_variable {
      name  = "ENV_NAME"
      value = var.env_name
    }

  }

  logs_config {
    cloudwatch_logs {
      group_name  = "govwifi-codebuild-ecs-update-service"
      stream_name = "govwifi-codebuild-push-image-to-ecr-log-stream"
    }

    s3_logs {
      status = "DISABLED"
    }
  }

  source {
    type      = "NO_SOURCE"
    buildspec = file("${path.module}/buildspec_restart_ecs_cluster.yml")
  }
}
