resource "random_id" "suffix" {
  byte_length = 2
}
resource "libvirt_volume" "f5xc-ce-volume" {
  name   = format("%s-%s-%s.qcow2", var.f5xc-ce-site-name, random_id.suffix.hex, var.f5xc-ce-node-name)
  pool   = var.f5xc-ce-storage-pool
  source = var.f5xc-ce-qcow2
  format = "qcow2"
}

resource "libvirt_cloudinit_disk" "f5xc-ce-cloudinit" {
  depends_on = [volterra_token.smsv2-token]
  name      = format("%s-%s-%s-cloud-init.iso", var.f5xc-ce-site-name, random_id.suffix.hex, var.f5xc-ce-node-name)
  pool      = var.f5xc-ce-storage-pool
  user_data = data.cloudinit_config.config.rendered
}

resource "libvirt_domain" "kvm-ce" {
  name   = format("%s-%s-%s", var.f5xc-ce-site-name, random_id.suffix.hex, var.f5xc-ce-node-name)
  memory = var.f5xc-ce-memory
  vcpu   = var.f5xc-ce-vcpu

  disk {
    volume_id = libvirt_volume.f5xc-ce-volume.id
  }

  cloudinit = libvirt_cloudinit_disk.f5xc-ce-cloudinit.id

  cpu {
    mode = "host-passthrough"
  }
 
  network_interface {
    network_name = var.f5xc-ce-network-slo
  }

  network_interface {
    network_name = var.f5xc-ce-network-sli
  }

  console {
    type        = "pty"
    target_type = "serial"
    target_port = "0"
  }
}
