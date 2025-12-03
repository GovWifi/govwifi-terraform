# /**
# * This code build project is only required to get the git source code for the given app, stores it in s3 which will trigger the codepipeline.
# * because as of 2024, it's not possible to override the source branch in code pipeline, so this messy workaround is required.
# **/
# resource "aws_codebuild_project" "govwifi_codebuild_get_source_apps_dev" {
#   for_each      = toset(var.deployed_app_names)
#   name          = "DEV-${each.key}-source"
#   description   = "This project is a workaround to get source from git and trigger codepipeline for ${each.key} because its not possible to change the branch in codepipeline 2024!"
#   build_timeout = "12"
#   service_role  = aws_iam_role.govwifi_codebuild.arn

#   artifacts {
#     location  = aws_s3_bucket.codepipeline_bucket.bucket
#     type      = "S3"
#     path      = "/"
#     packaging = "ZIP"
#   }

#   cache {
#     type     = "S3"
#     location = aws_s3_bucket.codepipeline_bucket.bucket
#   }

#   environment {
#     compute_type                = "BUILD_GENERAL1_SMALL"
#     image                       = "aws/codebuild/standard:6.0"
#     type                        = "LINUX_CONTAINER"
#     image_pull_credentials_type = "CODEBUILD"
#     privileged_mode             = true

#     environment_variable {
#       name  = "AWS_ACCOUNT_ID"
#       value = local.aws_account_id
#     }

#     environment_variable {
#       name  = "AWS_REGION"
#       value = "eu-west-2"
#     }

#     ## The S3 bucket used to store the source file.
#     environment_variable {
#       name  = "SOURCE_BUCKET"
#       value = aws_s3_bucket.codepipeline_bucket.bucket
#     }

#     ## this is the directory in which the zip file is saved, for each app, don't forget the trailing slash.
#     environment_variable {
#       name  = "OBJ_DIR"
#       value = "${local.s3_source_dir}/${each.key}/"
#     }
#   }

#   logs_config {
#     cloudwatch_logs {
#       group_name  = "govwifi-codebuild-get-source-log-group"
#       stream_name = "govwifi-codebuild-get-source-log-stream"
#     }

#     s3_logs {
#       status   = "ENABLED"
#       location = "${aws_s3_bucket.codepipeline_bucket.id}/build-log"
#     }
#   }

#   source_version = "master"

#   source {
#     type            = "GITHUB"
#     location        = "https://github.com/GovWifi/govwifi-${each.key}.git"
#     git_clone_depth = 1
#     buildspec       = file("${path.module}/buildspec_get_app_source.yml")
#   }
# }

# resource "aws_codebuild_webhook" "govwifi_app_webhook_dev" {
#   for_each     = toset(var.deployed_app_names)
#   project_name = aws_codebuild_project.govwifi_codebuild_get_source_apps_dev[each.key].name

#   build_type = "BUILD"

#   filter_group {
#     filter {
#       type    = "EVENT"
#       pattern = "PULL_REQUEST_MERGED"
#     }
#   }
# }
