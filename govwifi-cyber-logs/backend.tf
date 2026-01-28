# Update to correct backend terraform state storage details for your logs account.

terraform {
  required_version = "~> 1.9.6"

  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  backend "s3" {
    bucket  = "govwifi-cyberlogs"
    key     = "${var.env}/${var.region}/terraform.tfstate"
    region  = var.region
    encrypt = true
  }
}