### Begin Staging

resource "aws_ecr_repository" "govwifi_frontend_staging" {
  for_each = toset(var.frontend_docker_images)
  name     = "govwifi/staging/${each.key}"
}

resource "aws_ecr_repository_policy" "govwifi_frontend_policy_staging" {
  for_each   = toset(var.frontend_docker_images)
  repository = aws_ecr_repository.govwifi_frontend_staging[each.key].name
  policy     = data.aws_iam_policy_document.govwifi_ecr_repo_policy_staging.json
}

resource "aws_ecr_repository" "govwifi_frontend_staging_ire" {
  provider = aws.dublin
  for_each = toset(var.frontend_docker_images)
  name     = "govwifi/staging/${each.key}"
}

resource "aws_ecr_repository_policy" "govwifi_frontend_policy_staging_ire" {
  provider   = aws.dublin
  for_each   = toset(var.frontend_docker_images)
  repository = aws_ecr_repository.govwifi_frontend_staging[each.key].name
  policy     = data.aws_iam_policy_document.govwifi_ecr_repo_policy_staging.json
}

resource "aws_ecr_repository" "safe_restarter_ecr_staging" {
  name = "govwifi/staging/safe-restarter"
}

resource "aws_ecr_repository_policy" "govwifi_ecr_saferestater_policy_staging" {
  repository = aws_ecr_repository.safe_restarter_ecr_staging.name
  policy     = data.aws_iam_policy_document.govwifi_ecr_repo_policy_staging.json
}

resource "aws_ecr_repository" "database_backup_ecr_staging" {
  name = "govwifi/staging/database-backup"
}

resource "aws_ecr_repository_policy" "govwifi_ecr_database_backup_policy_staging" {
  repository = aws_ecr_repository.database_backup_ecr_staging.name
  policy     = data.aws_iam_policy_document.govwifi_ecr_repo_policy_staging.json
}

data "aws_iam_policy_document" "govwifi_ecr_repo_policy_staging" {
  statement {
    sid = "AllowPushPull"

    effect = "Allow"

    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:CompleteLayerUpload",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart"
    ]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.aws_staging_account_id}:root"]
    }

  }

}

resource "aws_ecr_repository" "govwifi_ecr_repo_deployed_apps_staging" {
  for_each = toset(var.deployed_app_names)
  name     = "govwifi/${each.key}/staging"
}

resource "aws_ecr_repository_policy" "govwifi_ecr_repo_policy_deployed_apps_staging" {
  for_each   = toset(var.deployed_app_names)
  repository = aws_ecr_repository.govwifi_ecr_repo_deployed_apps_staging[each.key].name
  policy     = data.aws_iam_policy_document.govwifi_ecr_repo_policy_staging.json
}

### End Staging

### Begin Production

resource "aws_ecr_repository" "govwifi_frontend_production" {
  for_each = toset(var.frontend_docker_images)
  name     = "govwifi/production/${each.key}"
}

resource "aws_ecr_repository_policy" "govwifi_frontend_policy_production" {
  for_each   = toset(var.frontend_docker_images)
  repository = aws_ecr_repository.govwifi_frontend_production[each.key].name
  policy     = data.aws_iam_policy_document.govwifi_ecr_repo_policy_production.json
}

resource "aws_ecr_repository" "govwifi_frontend_production_ire" {
  provider = aws.dublin
  for_each = toset(var.frontend_docker_images)
  name     = "govwifi/production/${each.key}"
}

resource "aws_ecr_repository_policy" "govwifi_frontend_policy_production_ire" {
  provider   = aws.dublin
  for_each   = toset(var.frontend_docker_images)
  repository = aws_ecr_repository.govwifi_frontend_production[each.key].name
  policy     = data.aws_iam_policy_document.govwifi_ecr_repo_policy_production.json
}

resource "aws_ecr_repository" "safe_restarter_ecr_production" {
  name = "govwifi/production/safe-restarter"
}

resource "aws_ecr_repository_policy" "govwifi_ecr_saferestater_policy_production" {
  repository = aws_ecr_repository.safe_restarter_ecr_production.name
  policy     = data.aws_iam_policy_document.govwifi_ecr_repo_policy_production.json
}

resource "aws_ecr_repository" "database_backup_ecr_production" {
  name = "govwifi/production/database-backup"
}

resource "aws_ecr_repository_policy" "govwifi_ecr_database_backup_policy" {
  repository = aws_ecr_repository.database_backup_ecr_production.name
  policy     = data.aws_iam_policy_document.govwifi_ecr_repo_policy_production.json
}

data "aws_iam_policy_document" "govwifi_ecr_repo_policy_production" {
  statement {
    sid = "AllowPushPull"

    effect = "Allow"

    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:CompleteLayerUpload",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart"
    ]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.aws_production_account_id}:root"]
    }

  }

}


resource "aws_ecr_repository" "govwifi_ecr_repo_deployed_apps_production" {
  for_each = toset(var.deployed_app_names)
  name     = "govwifi/${each.key}/production"
}

resource "aws_ecr_repository_policy" "govwifi_ecr_repo_policy_deployed_apps_production" {
  for_each   = toset(var.deployed_app_names)
  repository = aws_ecr_repository.govwifi_ecr_repo_deployed_apps_production[each.key].name
  policy     = data.aws_iam_policy_document.govwifi_ecr_repo_policy_production.json
}


### End Production

### Global

resource "aws_ecr_repository" "govwifi_ecr_repo_deployed_apps" {
  for_each = toset(var.deployed_app_names)
  name     = "govwifi/${each.key}"
}

resource "aws_ecr_repository_policy" "govwifi_ecr_repo_policy_deployed_apps" {
  for_each   = toset(var.deployed_app_names)
  repository = aws_ecr_repository.govwifi_ecr_repo_deployed_apps[each.key].name
  policy     = data.aws_iam_policy_document.govwifi_ecr_repo_policy_global.json
}

data "aws_iam_policy_document" "govwifi_ecr_repo_policy_global" {
  statement {
    sid = "AllowPushPull"

    effect = "Allow"

    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:CompleteLayerUpload",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart"
    ]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.aws_production_account_id}:root", "arn:aws:iam::${local.aws_staging_account_id}:root"]
    }

  }

}
