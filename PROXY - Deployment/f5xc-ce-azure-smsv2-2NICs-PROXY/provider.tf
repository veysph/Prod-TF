terraform {
  required_providers {
    volterra = {
      source  = "volterraedge/volterra"
      version = ">=0.11.42"
    }

    azurerm = {
      version = "3.49.0"
    }

    local = ">= 2.2.3"
    null  = ">= 3.1.1"
  }
}

provider "azurerm" {
  features {}
}

provider "volterra" {
  api_p12_file = var.f5xc_api_p12_file
  url          = var.f5xc_api_url
}