terraform {
  required_providers {
    volterra = {
      source  = "volterraedge/volterra"
      version = ">=0.11.42"
    }

    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    local = ">= 2.2.3"
    null  = ">= 3.1.1"
  }
}

provider "aws" {
  region                   = var.aws-region
  shared_config_files      = var.aws_shared_config_files
  shared_credentials_files = var.aws_shared_credentials_files
  profile                  = var.aws_profile
}

provider "volterra" {
  api_p12_file = var.f5xc_api_p12_file
  url          = var.f5xc_api_url
}