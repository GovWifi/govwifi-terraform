resource "aws_codepipeline" "development_deploy_apps_pipeline" {
  for_each = toset(var.deployed_app_names)
  name     = "development-${each.key}-app-pipeline"
  role_arn = aws_iam_role.govwifi_codepipeline_global_role.arn

  artifact_store {
    region   = "eu-west-2"
    location = aws_s3_bucket.codepipeline_bucket.bucket
    type     = "S3"

    encryption_key {
      id   = aws_kms_key.codepipeline_key.arn
      type = "KMS"
    }
  }

  artifact_store {
    location = aws_s3_bucket.codepipeline_bucket_ireland.bucket
    type     = "S3"
    region   = "eu-west-1"

    encryption_key {
      id   = aws_kms_key.codepipeline_key_ireland.arn
      type = "KMS"
    }
  }

  stage {
    name = "Source"
    action {
      name             = "S3-${each.key}-DEV"
      category         = "Source"
      owner            = "AWS"
      provider         = "S3"
      version          = 1
      run_order        = 1
      output_artifacts = ["${each.key}-source-art"]

      configuration = {
        S3Bucket             = aws_s3_bucket.codepipeline_bucket.bucket
        S3ObjectKey          = "${local.s3_source_dir}/${each.key}/app.zip"
        PollForSourceChanges = false
      }
    }
  }

  stage {
    name = "Build"

    action {
      name            = "Build-push-${each.key}-ECR-DEV"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      region          = "eu-west-2"
      input_artifacts = ["${each.key}-source-art"]
      version         = 1
      run_order       = 1
      configuration = {
        ProjectName = "${aws_codebuild_project.govwifi_codebuild_deployed_app[each.key].name}"
        EnvironmentVariables = jsonencode([
          {
            name  = "STAGE"
            value = "development"
            type  = "PLAINTEXT"
          }
        ])
      }
    }
  }

  stage {
    name = "Deploy"

    dynamic "action" {
      for_each = local.app[each.key].regions
      content {
        name            = "Update-${each.key}-ECS-${action.value}-DEV"
        category        = "Build"
        owner           = "AWS"
        provider        = "CodeBuild"
        region          = action.value
        input_artifacts = ["${each.key}-source-art"]
        # This resource lives in the Dev, Staging & Production environments. It will always have to
        # either be hardcoded or retrieved from the AWS secrets or parameter store
        role_arn  = "arn:aws:iam::${local.aws_development_account_id}:role/govwifi-codebuild-role"
        version   = 1
        run_order = 1
        configuration = {
          ProjectName = "govwifi-ecs-update-service-${each.key}"
        }
      }
    }
  }

  dynamic "stage" {
      for_each = contains(local.integration_tests, each.key) ? [each.key] : []
      content {
        name = "Integration_Tests"

        action {

          name            = "Integration-tests-${each.key}-DEV"
          category        = "Test"
          owner           = "AWS"
          provider        = "CodeBuild"
          input_artifacts = ["${each.key}-source-art"]
          # This resource lives in the Dev, Staging & Production environments. It will always have to
          # either be hardcoded or retrieved from the AWS secrets or parameter store
          version   = 1
          run_order = 1
          configuration = {
            ProjectName = aws_codebuild_project.govwifi_codebuild_acceptance_tests.name
          }
        }
      }
  }

  stage {
    name = "Smoke_Tests"

    action {
      name            = "Smoke-tests-${each.key}-DEV"
      category        = "Test"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["${each.key}-source-art"]
      # This resource lives in the development & Production environments. It will always have to
      # either be hardcoded or retrieved from the AWS secrets or parameter store
      role_arn  = "arn:aws:iam::${local.aws_development_account_id}:role/govwifi-codebuild-role"
      version   = "1"
      run_order = 1
      configuration = {
        ProjectName = "govwifi-smoke-tests"
      }
    }
  }

}