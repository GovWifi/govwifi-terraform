terraform {
  required_version = "~> 1.9.6"

  backend "s3" {
    bucket = "govwifi-development-tfstate-eu-west-2"

    key    = "development-tfstate"
    region = "eu-west-2"
  }

  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

  default_tags {
    tags = {
      Environment = title(local.env_name)
    }
  }
}

module "tfstate" {
  providers = {
    aws             = aws.london
    aws.replication = aws.dublin
  }

  source   = "../../new-terraform-state"
  env_name = local.env_name
}
