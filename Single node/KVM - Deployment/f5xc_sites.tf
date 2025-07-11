resource "volterra_securemesh_site_v2" "site" {
  name                    = format("%s-%s", var.f5xc-ce-site-name, random_id.suffix.hex)
  namespace               = "system"
  description             = var.f5xc_sms_description
  block_all_services      = true
  logs_streaming_disabled = true
  enable_ha               = false
  labels = {
    "ves.io/provider" = "ves-io-KVM"
  }

  re_select {
    geo_proximity = true
  }

  kvm {
    not_managed {}
  }
}

resource "volterra_token" "smsv2-token" {
  depends_on = [volterra_securemesh_site_v2.site]
  name       = format("%s-%s-%s", var.f5xc-ce-site-name, random_id.suffix.hex, "token")
  namespace  = "system"
  type       = 1
  site_name  = volterra_securemesh_site_v2.site.name
}

data "cloudinit_config" "config" {
  gzip          = false
  base64_encode = false

  part {
    content_type = "text/cloud-config"
    content = yamlencode({
      write_files = [
        {
          path        = "/etc/vpm/user_data"
          permissions = "0644"
          owner       = "root"
          content     = <<-EOT
            token: ${replace(volterra_token.smsv2-token.id, "id=", "")}
            # slo_ip: <XXX.XXX.XXX.XXX/XX>
            # slo_gateway: XXX.XXX.XXX.XXX
          EOT
        }
      ]
    })
  }
}