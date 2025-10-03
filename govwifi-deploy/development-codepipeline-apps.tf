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
      name             = "Github-${each.key}-development"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = 1
      run_order        = 1
      output_artifacts = ["${each.key}-source-art"]

      configuration = {
        Owner                = local.git_owner
        Repo                 = local.app[each.key].repo
        Branch               = local.branch
        OAuthToken           = jsondecode(data.aws_secretsmanager_secret_version.github_token.secret_string)["token"]
        PollForSourceChanges = true
      }
    }
  }

  stage {
    name = "Build"

    action {
      name            = "Build-push-${each.key}-development-ECR"
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
        name            = "Update-${each.key}-development-${action.value}-ECS"
        category        = "Build"
        owner           = "AWS"
        provider        = "CodeBuild"
        region          = action.value
        input_artifacts = ["${each.key}-source-art"]
        # This resource lives in the development & Production environments. It will always have to
        # either be hardcoded or retrieved from the AWS secrets or parameter store
        role_arn  = "arn:aws:iam::${local.aws_development_account_id}:role/govwifi-codebuild-role"
        version   = "1"
        run_order = 1
        configuration = {
          ProjectName = "govwifi-ecs-update-service-${each.key}"
        }
      }
    }
  }

  stage {
    name = "Test"

    action {
      name            = "Smoketests-${each.key}-development"
      category        = "Test"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["${each.key}-source-art"]
      # This resource lives in the development & Production environments. It will always have to
      # either be hardcoded or retrieved from the AWS secrets or parameter store
      role_arn = "arn:aws:iam::${local.aws_development_account_id}:role/govwifi-codebuild-role"
      version  = "1"

      configuration = {
        ProjectName = "govwifi-smoke-tests"
      }
    }
  }
}