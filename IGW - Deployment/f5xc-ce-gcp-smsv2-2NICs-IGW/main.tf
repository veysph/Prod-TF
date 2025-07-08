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
  machine_type = var.gcp-instance-flavor
  zone         = "${var.gcp_region}-a"
  tags         = ["f5xc-ce"]
  can_ip_forward = true

  boot_disk {
    initialize_params {
      image = "projects/f5-7626-networks-public/global/images/f5xc-ce-9202444-20250102052432"
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