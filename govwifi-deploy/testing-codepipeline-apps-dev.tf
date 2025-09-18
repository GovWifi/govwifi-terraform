resource "aws_codepipeline" "testing_dev_apps_pipeline" {
  #for_each      = toset(var.deployed_app_names)
  for_each      = toset(var.test_app_pipeline)
  name          = "TESTING-DEV-${each.key}-app--pipeline"
  role_arn      = aws_iam_role.govwifi_codepipeline_global_role.arn
  pipeline_type = "V2"

  variable {
    name          = "frontend"
    default_value = local.app["frontend"].branch
    description   = "The Git branch for frontend acceptance tests to use."
  }
  variable {
    name          = "authentication-api"
    default_value = local.app["authentication-api"].branch
    description   = "The Git branch for authentication acceptance tests to use."
  }
  variable {
    name          = "logging-api"
    default_value = local.app["logging-api"].branch
    description   = "The Git branch for logging acceptance tests to use."
  }

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
      name             = "Github-${each.key}"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = 1
      run_order        = 1
      output_artifacts = ["${each.key}-source-art"]

      configuration = {
        Owner                = local.git_owner
        Repo                 = local.app[each.key].repo
        Branch               = local.app[each.key].branch
        OAuthToken           = jsondecode(data.aws_secretsmanager_secret_version.github_token.secret_string)["token"]
        PollForSourceChanges = false ## changes now detected via codebuild.
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
        ProjectName = "${aws_codebuild_project.testing_codebuild_build_push_app[each.key].name}"
        EnvironmentVariables = jsonencode([
          {
            name  = "STAGE"
            value = "alpaca"
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
        role_arn  = "arn:aws:iam::${local.aws_alpaca_account_id}:role/govwifi-codebuild-role"
        version   = 1
        run_order = 1
        configuration = {
          ProjectName = "govwifi-ecs-update-service-${each.key}"
        }
      }
    }
  }

  stage {
    name = "Test"

    dynamic "action" {
      for_each = contains(local.integration_tests, each.key) ? [each.key] : []
      content {
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
          EnvironmentVariables = jsonencode([
            {
              name  = "FRONTEND_BRANCH"
              value = "#{variables.frontend}"
              type  = "PLAINTEXT"
            },
            {
              name  = "AUTH_API_BRANCH"
              value = "#{variables.authentication-api}"
              type  = "PLAINTEXT"
            },
            {
              name  = "LOGGING_API_BRANCH"
              value = "#{variables.logging-api}"
              type  = "PLAINTEXT"
            }
          ])
        }
      }
    }


    action {
      name            = "Smoke-tests-${each.key}-DEV"
      category        = "Test"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["${each.key}-source-art"]
      # This resource lives in the alpaca & Production environments. It will always have to
      # either be hardcoded or retrieved from the AWS secrets or parameter store
      role_arn  = "arn:aws:iam::${local.aws_alpaca_account_id}:role/govwifi-codebuild-role"
      version   = 1
      run_order = 1
      configuration = {
        ProjectName = "govwifi-smoke-tests"
      }
    }
  }
}