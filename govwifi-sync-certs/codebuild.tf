resource "aws_codebuild_project" "govwifi_codebuild_sync_certs" {
  name          = "govwifi-codebuild-sync-certs"
  description   = "This project uploads the TLS certificates in govwifi-build to S3 where they are picked up by the Radius servers on restart "
  build_timeout = "5"
  service_role  = "arn:aws:iam::${var.aws_account_id}:role/govwifi-sync-certs-codebuild-role"

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
      name  = "DOCKER_HUB_AUTHTOKEN_ENV"
      value = data.aws_secretsmanager_secret_version.docker_hub_authtoken.secret_string
    }

    environment_variable {
      name  = "DOCKER_HUB_USERNAME_ENV"
      value = data.aws_secretsmanager_secret_version.docker_hub_username.secret_string
    }

    environment_variable {
      name  = "GPG_FINGERPRINT"
      value = data.aws_secretsmanager_secret_version.gpg_fingerprint.secret_string
    }

    environment_variable {
      name  = "GPG_KEY"
      type  = "SECRETS_MANAGER"
      value = "deploy/gpg_key"
    }

    environment_variable {
      name  = "GIT_USER"
      value = jsondecode(data.aws_secretsmanager_secret_version.github_token.secret_string)["username"]
    }

    environment_variable {
      name  = "GIT_TOKEN"
      value = jsondecode(data.aws_secretsmanager_secret_version.github_token.secret_string)["token"]
    }

    environment_variable {
      name  = "GOVWIFI_ENV"
      value = var.env
    }

    environment_variable {
      name  = "BRANCH"
      value = "master"
    }
  }

  source {
    type      = "NO_SOURCE"
    buildspec = file("${path.module}/buildspec.yml")

  }

  logs_config {
    cloudwatch_logs {
      group_name  = "govwifi-sync-cert-group"
      stream_name = "govwifi-sync-cert-stream"
    }

    s3_logs {
      status   = "ENABLED"
      location = "${aws_s3_bucket.sync_certs_bucket.id}/sync-cert-log"
    }
  }

}
