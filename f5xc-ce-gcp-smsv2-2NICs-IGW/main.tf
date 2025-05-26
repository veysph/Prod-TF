#Random generator
resource "random_id" "suffix" {
  byte_length = 2
}

# VPC Data Sources
data "google_compute_network" "public_vpc" {
  name    = "pveys-smsv2-public"
  project = var.gcp_project
}

data "google_compute_network" "private_vpc" {
  name    = "pveys-smsv2-private"
  project = var.gcp_project
}

# Subnet Data Sources
data "google_compute_subnetwork" "outside" {
  name   = "pveys-sub1-smsv2-public"
  region = var.gcp_region
}

data "google_compute_subnetwork" "inside" {
  name   = "pveys-sub1-smsv2-private"
  region = var.gcp_region
}

#
#F5XC
#
resource "volterra_token" "smsv2-token" {
  depends_on = [volterra_securemesh_site_v2.site]
  name       = "${var.f5xc-ce-site-name}-token"
  namespace  = "system"
  type       = 1
  site_name  = volterra_securemesh_site_v2.site.name
}

data "cloudinit_config" "f5xc-ce_config" {
  gzip          = false
  base64_encode = false

  part {
    content_type = "text/cloud-config"
    content = yamlencode({
      #cloud-config
      write_files = [
        {
          path        = "/etc/vpm/user_data"
          permissions = "0644"
          owner       = "root"
          content     = <<-EOT
            token: ${trimprefix(trimprefix(volterra_token.smsv2-token.id, "id="), "\"")}
          EOT
        }
      ]
    })
  }
}

resource "volterra_securemesh_site_v2" "site" {
  name                    = format("%s-%s", var.f5xc-ce-site-name, random_id.suffix.hex)
  namespace               = "system"
  description             = var.f5xc_sms_description
  block_all_services      = true
  logs_streaming_disabled = true
  enable_ha               = false

  labels = {
    "ves.io/provider" = "ves-io-GCP"
  }

  re_select {
    geo_proximity = true
  }

  gcp {
    not_managed {}
  }
}

#
#GCP computing
#
# Public IP Allocation
resource "google_compute_address" "public_ip" {
  name         = format("%s-%s-%s", var.f5xc-ce-site-name, random_id.suffix.hex, "public-ip")
  address_type = "EXTERNAL"
  region       = var.gcp_region
  network_tier = "STANDARD"
}

# Compute Instance
resource "google_compute_instance" "smsv2_gcp" {
  name         = format("%s-%s", var.f5xc-ce-site-name, random_id.suffix.hex)
  machine_type = "n2-standard-8"
  zone         = "${var.gcp_region}-a"
  tags         = ["f5xc-ce"]
  can_ip_forward = true

  boot_disk {
    initialize_params {
      image = "f5xc-emea-smsv2-image"
      size  = 80
    }
  guest_os_features = ["MULTI_IP_SUBNET"]
  }

  network_interface {
    subnetwork = data.google_compute_subnetwork.outside.self_link
    network_ip = var.slo-private-ip
    access_config {
      nat_ip = google_compute_address.public_ip.address
      network_tier = "STANDARD"
    }
  }

  network_interface {
    subnetwork = data.google_compute_subnetwork.inside.self_link
    network_ip = var.sli-private-ip
  }

  metadata = {
    user-data = data.cloudinit_config.f5xc-ce_config.rendered
    ssh-keys  = "${var.ssh_username}:${var.ssh_key}"
  }

  service_account {
    scopes = ["cloud-platform"]
  }
}