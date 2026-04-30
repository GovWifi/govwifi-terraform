terraform {
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