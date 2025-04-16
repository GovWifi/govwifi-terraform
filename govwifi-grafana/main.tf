terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    time = {
      source  = "hashicorp/time",
      version = "~> 0.11.1"
    }
  }
}
