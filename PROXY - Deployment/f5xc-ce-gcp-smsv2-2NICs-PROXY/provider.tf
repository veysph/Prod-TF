terraform {
  required_providers {
    volterra = {
      source  = "volterraedge/volterra"
      version = ">=0.11.42"
    }

    google = {
      source  = "hashicorp/google"
      version = "~> 6.8"
    }

    local = ">= 2.2.3"
    null  = ">= 3.1.1"
  }
}

provider "google" {
  project     = var.gcp_project
  region      = var.gcp_region
}

provider "volterra" {
  api_p12_file = var.f5xc_api_p12_file
  url          = var.f5xc_api_url
}