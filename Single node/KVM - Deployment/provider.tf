terraform {
  required_providers {
    volterra = {
      source  = "volterraedge/volterra"
      version = ">=0.11.42"
    }

    libvirt = {
      source = "dmacvicar/libvirt"
      version = ">=0.7.6"
    }

    local = ">= 2.2.3"
    null  = ">= 3.1.1"
  }
}

provider "volterra" {
  api_p12_file = var.f5xc_api_p12_file
  url          = var.f5xc_api_url
}

provider "libvirt" {
  uri = "qemu:///system"
}