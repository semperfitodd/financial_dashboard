provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = var.environment
      Owner       = "Todd"
      Provisioner = "Terraform"
    }
  }
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.94.1"
    }
  }
  required_version = "1.11.4"
}