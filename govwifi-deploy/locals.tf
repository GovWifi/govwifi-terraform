locals {
  aws_staging_account_id = jsondecode(data.aws_secretsmanager_secret_version.staging_aws_account_no.secret_string)["account-id"]
}

locals {
  aws_production_account_id = jsondecode(data.aws_secretsmanager_secret_version.production_aws_account_no.secret_string)["account-id"]
}

locals {
  aws_alpaca_account_id = jsondecode(data.aws_secretsmanager_secret_version.alpaca_aws_account_no.secret_string)["account-id"]
}

data "aws_caller_identity" "current" {}

locals {
  aws_account_id = data.aws_caller_identity.current.account_id
}

locals {
  git_owner         = "GovWifi"
  branch            = "master"
  s3_source_dir     = "source"
  integration_tests = ["logging-api", "authentication-api"]
  app = {
    admin = {
      repo    = "govwifi-admin"
      regions = ["eu-west-2"]
    }
    logging-api = {
      repo    = "govwifi-logging-api"
      regions = ["eu-west-2"]
    }
    authentication-api = {
      repo    = "govwifi-authentication-api"
      regions = ["eu-west-1", "eu-west-2"]
    }
    user-signup-api = {
      repo    = "govwifi-user-signup-api"
      regions = ["eu-west-2"]
    }
  }
}
