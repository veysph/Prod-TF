#
# F5XC HTTP Load Balancer configuration
#
resource "volterra_http_loadbalancer" "test_lb" {
  count      = var.create_f5xc_loadbalancer ? 1 : 0
  depends_on = [volterra_virtual_site.vsite]
  name       = var.lb_name
  namespace  = var.namespace
  
  # Domain configuration
  domains = var.domains
  
  # HTTP configuration on port 80
  http {
    dns_volterra_managed = false
    port                 = var.http_port
  }
  
  # Advertise custom configuration
  advertise_custom {
    advertise_where {
      use_default_port = true
      virtual_site {
        network = var.virtual_site_network
        virtual_site {
          name      = var.f5xc_virtual_site_name
          namespace = var.virtual_site_namespace
        }
      }
    }
  }
  
  # Load balancing algorithm
  round_robin = true
  
  # Direct response route configuration
  routes {
    direct_response_route {
      http_method = "ANY"
      incoming_port {
        no_port_match = true
      }
      path {
        prefix = "/"
      }
      route_direct_response {
        response_body = var.response_body
        response_code = var.response_code
      }
    }
  }
  
  # Security and feature configurations (disabled as per specs)
  disable_waf                     = !var.enable_waf
  disable_rate_limit              = !var.enable_rate_limit
  disable_bot_defense             = !var.enable_bot_defense
  disable_api_definition          = true
  disable_api_discovery           = true
  disable_malicious_user_detection = true
  disable_ip_reputation           = true
  disable_client_side_defense     = true
  
  # No challenge configuration
  no_challenge = true
  
  # System default timeouts
  system_default_timeouts = true
  
  # User identification
  user_id_client_ip = true
  
  # No service policies
  no_service_policies = true
  
  # Disable location addition
  add_location = false
}