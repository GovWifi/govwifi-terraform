terraform {
  required_version = "~> 1.9.6"

  backend "s3" {
    # Interpolation is not allowed here.
    #bucket = "${lower(local.product_name)}-${lower(local.env_name)}-${lower(var.aws_region_name)}-tfstate"
    #key    = "${lower(var.aws_region_name)}-tfstate"
    #region = "${var.aws_region}"
    bucket = "govwifi-tools-tfstate"

    key    = "govwifi-terraform-tfstate"
    region = "eu-west-2"
  }
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  alias  = "main"
  region = var.aws_region
}

provider "aws" {
  alias  = "dublin"
  region = "eu-west-1"
}

module "govwifi_deploy" {
  providers = {
    aws        = aws.main
    aws.dublin = aws.dublin
  }

  source = "../../govwifi-deploy"

  deployed_app_names     = ["user-signup-api", "logging-api", "admin", "authentication-api"]
  built_app_names        = ["frontend", "safe-restarter", "database-backup", "smoke-tests"]
  frontend_docker_images = ["raddb", "frontend"]
}

module "govwifi_account_policy" {
  providers = {
    aws = aws.main
  }

  source = "../../govwifi-account-policy"

  aws_region     = var.aws_region
  env            = "tools"
  aws_account_id = local.aws_account_id
  region_name    = "London"

}
