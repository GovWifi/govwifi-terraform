/**
* This code build project is only required to update the source branch name for codepipeline, which will then trigger the codepipeline.
* because as of 202, it's STILL not possible to override the source branch in code pipeline, so this messy workaround is required.
* The source branch name is taken from the git branch which triggers the codebuild project via the webhook,
* to build with a custom branch, create a PR and add the "Deploy-to-DEV" label, which will trigger this codebuild.
**/
resource "aws_codebuild_project" "testing_codebuild_update_source_branch" {
  #for_each      = toset(var.deployed_app_names)
  for_each      = toset(var.test_app_pipeline)
  name          = "TESTING-${each.key}-deploy-DEV-codepipeline"
  description   = "This project is a workaround to update the DEV pipeline source branch name and trigger codepipeline for ${each.key} because its not possible to change the source branch in codepipeline in 2025!"
  build_timeout = "12"
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

    environment_variable {
      ## This is used to identify which pipeline to update the source branch for.
      name  = "PIPELINE_NAME"
      value = aws_codepipeline.testing_dev_apps_pipeline[each.key].name
    }

    environment_variable {
      name  = "MAIN_BRANCH" ## don't update this, is this used to compare the main branch to custom branch
      value = local.app[each.key].branch
    }
    environment_variable {
      name  = "APPLICATION_NAME" ## don't update this, is this used to compare the main branch to custom branch
      value = each.key
    }
  }

  source_version = local.app[each.key].branch

  source {
    type            = "GITHUB"
    location        = "https://github.com/GovWifi/govwifi-${each.key}.git"
    git_clone_depth = 1
    buildspec       = file("${path.module}/testing-buildspec-deploy-pipeline-dev.yml")
  }


  logs_config {
    cloudwatch_logs {
      group_name  = "govwifi-codebuild-update-branch-log-group"
      stream_name = "govwifi-codebuild-update-branch-log-stream"
    }

    s3_logs {
      status   = "ENABLED"
      location = "${aws_s3_bucket.codepipeline_bucket.id}/build-log"
    }
  }
}

### THIS is what triggers this codebuild project to update the source branch based on the git branch which called it,
# which then updates and runs the codepipeline.
resource "aws_codebuild_webhook" "testing_app_webhook_pipeline_trigger" {
  #for_each     = toset(var.built_app_names)
  for_each     = toset(var.test_app_pipeline)
  project_name = aws_codebuild_project.testing_codebuild_update_source_branch[each.key].name

  build_type = "BUILD"

  filter_group {
    filter {
      type    = "EVENT"
      pattern = "PULL_REQUEST_UPDATED, PULL_REQUEST_REOPENED, PULL_REQUEST_CREATED, PULL_REQUEST_MERGED"
    }
  }
  depends_on = [
    aws_codebuild_project.testing_codebuild_update_source_branch
  ]
}