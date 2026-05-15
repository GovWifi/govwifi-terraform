resource "aws_codepipeline" "testing_staging_prod_apps_pipeline" {
  #for_each = toset(var.deployed_app_names)
  for_each = toset(var.test_app_pipeline)
  name     = "TESTING-STAGING-PROD-${each.key}-app-pipeline"
  role_arn = aws_iam_role.govwifi_codepipeline_global_role.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_bucket.bucket
    type     = "S3"
    region   = "eu-west-2"

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
      name             = "Github-${each.key}"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = 1
      run_order        = 1
      output_artifacts = ["${each.key}-source-art"]

      configuration = {
        Owner      = local.git_owner
        Repo       = local.app[each.key].repo
        Branch     = local.app[each.key].branch
        OAuthToken = jsondecode(data.aws_secretsmanager_secret_version.github_token.secret_string)["token"]
        #PollForSourceChanges = true
        PollForSourceChanges = false ## just while testing.
      }
    }
  }

  stage {
    name = "Build_STAGING"

    action {
      name            = "Build-push-${each.key}-ECR-STAGING"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      region          = "eu-west-2"
      input_artifacts = ["${each.key}-source-art"]
      version         = 1
      run_order       = 1
      configuration = {
        ProjectName = "${aws_codebuild_project.testing_codebuild_build_push_app[each.key].name}"
        EnvironmentVariables = jsonencode([
          {
            name  = "STAGE"
            value = "staging"
            type  = "PLAINTEXT"
          }
        ])
      }
    }
  }

  stage {
    name = "Deploy_STAGING"

    dynamic "action" {
      for_each = local.app[each.key].regions
      content {
        name            = "Update-${each.key}-ECS-${action.value}-STAGING"
        category        = "Build"
        owner           = "AWS"
        provider        = "CodeBuild"
        region          = action.value
        input_artifacts = ["${each.key}-source-art"]
        # This resource lives in the Staging & Production environments. It will always have to
        # either be hardcoded or retrieved from the AWS secrets or parameter store
        role_arn  = "arn:aws:iam::${local.aws_staging_account_id}:role/govwifi-codebuild-role"
        version   = "1"
        run_order = 1
        configuration = {
          ProjectName = "govwifi-ecs-update-service-${each.key}"
        }
      }
    }
  }

  stage {
    name = "Test_STAGING"
    dynamic "action" {
      for_each = contains(local.integration_tests, each.key) ? [each.key] : []
      content {
        name            = "Integration-tests-${each.key}-STAGING"
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

    action {
      name            = "Smoke-tests-${each.key}-STAGING"
      category        = "Test"
      owner           = "AWS"
      provider        = "CodeBuild"
      region          = "eu-west-2"
      input_artifacts = ["${each.key}-source-art"]

      # This resource lives in the Staging & Production environments. It will always have to
      # either be hardcoded or retrieved from the AWS secrets or parameter store
      role_arn  = "arn:aws:iam::${local.aws_staging_account_id}:role/govwifi-codebuild-role"
      version   = 1
      run_order = 1
      configuration = {
        ProjectName = "govwifi-smoke-tests"
      }
    }
  }


  stage {
    name = "Release_PRODUCTION"

    action {
      name     = "Release-${each.key}-to-PRODUCTION"
      category = "Approval"
      owner    = "AWS"
      provider = "Manual"
      region   = "eu-west-2"
      version  = 1
    }
  }


  stage {
    name = "Build_PRODUCTION"

    action {
      name            = "Copy-push-${each.key}-image-ECR-PRODUCTION"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["${each.key}-source-art"]
      version         = 1
      configuration = {
        ProjectName = aws_codebuild_project.testing_codebuild_copy_push_app_production.name
        EnvironmentVariables = jsonencode([
          {
            name  = "APP",
            value = each.key,
            type  = "PLAINTEXT"
          }
        ])
      }
    }
  }

  dynamic "stage" {
    for_each = each.key == "frontend" ? [] : [1]
    content {
      name = "Deploy_PRODUCTION"
      dynamic "action" {
        for_each = local.app[each.key].regions
        content {
          name            = "Update-${each.key}-ECS-${action.value}-PRODUCTION"
          category        = "Build"
          owner           = "AWS"
          provider        = "CodeBuild"
          region          = action.value
          input_artifacts = ["${each.key}-source-art"]
          role_arn        = "arn:aws:iam::${local.aws_production_account_id}:role/govwifi-codebuild-role"
          version         = 1
          run_order       = 1
          configuration = {
            ProjectName = "govwifi-ecs-update-service-${each.key}"
          }
        }
      }
    }
  }
}
