resource "aws_cloudwatch_log_group" "ecs_frontend_reset" {
  name              = "govwifi-codebuild-ecs-frontend-reset-service-log-group"
  retention_in_days = 30
}

resource "aws_codebuild_project" "ecs_service_radius_frontend_task_reset" {
  name          = "${var.env_name}-${var.aws_region_name}-frontend-radius-task-scale-down"
  description   = "After a scale up event, use this Codebuild Job to reset the desired tasks back to desired levels"
  build_timeout = "5"
  service_role  = "arn:aws:iam::${var.aws_account_id}:role/govwifi-codebuild-role"

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:7.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true

    ## Use this to set the minimum desired tasks
    environment_variable {
      name  = "MIN_TASKS"
      value = var.radius_task_count_min
    }

    environment_variable {
      name  = "CLUSTER_NAME"
      value = aws_ecs_cluster.frontend_fargate.name
    }

    environment_variable {
      name  = "SERVICE_NAME"
      value = aws_ecs_service.load_balanced_frontend_service.name
    }
  }

  source {
    type      = "NO_SOURCE"
    buildspec = file("${path.module}/buildspec.yml")
  }

  logs_config {
    cloudwatch_logs {
      group_name  = aws_cloudwatch_log_group.ecs_frontend_reset.name
      stream_name = "govwifi-codebuild-ecs-frontend-reset-service-log-stream"
    }

    s3_logs {
      status = "DISABLED"
    }
  }
  tags = {
    Purpose = "manual-ecs-radius-scale-down"
  }

}