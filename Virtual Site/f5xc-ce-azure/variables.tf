variable "resource_group_name" {
    description = "Name of the Azure resource group"
    type        = string
    default     = "my-resource-group"
}

variable "vnet_name" {
    description = "Name of the Azure Virtual Network"
    type        = string
    default     = "my-vnet"
}

variable "outside_subnet_name" {
    description = "Name of the outside subnet (public subnet with NAT Gateway for outbound connectivity)"
    type        = string
    default     = "my-outside-subnet"
}

variable "inside_subnet_name" {
    description = "Name of the inside/private subnet for internal traffic"
    type        = string
    default     = "my-inside-subnet"
}

variable "lb_public_subnet_name" {
  type        = string
  description = "Name of the public subnet for the Load Balancer"
  default     = "my-public-subnet"
}

variable "owner" {
    description = "Owner tag for Azure resources"
    type        = string
    default     = "your-name"
}

variable "f5xc-ce-site-name" {
    description = "F5XC CE site/cluster name (will be used as prefix for resources)"
    type        = string
    default     = "my-f5xc-site"
}

variable "ssh_public_key" {
    description = "SSH public key for VM access"
    type        = string
    default     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQ..."
}

variable "ssh_username" {
  type        = string
  description = "SSH user for the F5XC CE"
  default     = "cloud-user"
}

variable "location" {
    description = "Azure region for F5XC CE deployment"
    type        = string
    default     = "West US 2"
}

variable "f5xc_sms_instance_type" {
  type        = string
  description = "Azure VM size (allowed: Standard_D8_v4, Standard_D16_v4)"
  default = "Standard_D8_v4"

  validation {
    condition     = contains(["Standard_D8_v4", "Standard_D16_v4"], var.f5xc_sms_instance_type)
    error_message = "Invalid Azure VM size. Allowed values are: Standard_D8_v4 or Standard_D16_v4."
  }
}

variable "f5xc_sms_storage_account_type" {
  description = "Defines the type of storage account to be created. Valid options are Standard_LRS, Standard_ZRS, Standard_GRS, Standard_RAGRS, Premium_LRS."
  type        = string
  default     = "Standard_LRS"
}

variable "f5xc_api_url" {
  type    = string
  default = "https://your-tenant.console.ves.volterra.io/api"
}

variable "f5xc_api_p12_file" {
  type        = string
  description = "Path to F5XC API credentials P12 file (download from F5XC console)"
  default     = "/path/to/your/api-creds.p12"
}

variable "f5xc_sms_description" {
  type    = string
  default = "F5XC Azure site created with Terraform"
}

variable "f5xc_vsite_key" {
  type        = string
  description = "F5XC virtual site key for site selection"
  default     = "my-vsite-key"
}

variable "f5xc_vsite_key_label" {
  type        = string
  description = "F5XC virtual site key label value"
  default     = "yes"
}

variable "create_f5xc_vsite_resources" {
  type        = bool
  description = "Create the F5XC vsite key and label resources"
  default     = true
}

variable "node_count" {
  type        = number
  description = "Number of F5XC CE nodes to deploy"
  default     = 1
  validation {
    condition     = var.node_count >= 1 && var.node_count <= 10
    error_message = "Node count must be between 1 and 10."
  }
}

variable "deploy_lb" {
  type        = bool
  description = "Deploy Azure Load Balancer"
  default     = false
}

variable "lb_target_ports" {
  type        = list(number)
  description = "Target ports for Load Balancer to forward traffic to F5XC CE nodes"
  default     = [80, 443]
}

variable "lb_health_check_port" {
  type        = number
  description = "Port for Load Balancer health check"
  default     = 80
}

variable "create_f5xc_virtual_site" {
  type        = bool
  description = "Create F5XC Virtual Site"
  default     = false
}

variable "f5xc_virtual_site_name" {
  type        = string
  description = "F5XC Virtual Site name"
  default     = ""
}

variable "create_f5xc_loadbalancer" {
  type        = bool
  description = "Create F5XC HTTP Load Balancer"
  default     = false
}

variable "lb_name" {
  type        = string
  description = "Load balancer name"
  default     = ""
}

variable "namespace" {
  type        = string
  description = "Namespace for F5XC resources"
  default     = "shared"
}

variable "domains" {
  type        = list(string)
  description = "Domain names for the load balancer"
  default     = []
}

variable "http_port" {
  type        = number
  description = "HTTP port for the load balancer"
  default     = 80
}

variable "virtual_site_network" {
  type        = string
  description = "Virtual site network type"
  default     = "SITE_NETWORK_OUTSIDE"
}

variable "virtual_site_namespace" {
  type        = string
  description = "Virtual site namespace"
  default     = "shared"
}

variable "response_code" {
  type        = number
  description = "Direct response code"
  default     = 200
}

variable "response_body" {
  type        = string
  description = "Direct response body"
  default     = "HC OK"
}

variable "enable_waf" {
  type        = bool
  description = "Enable WAF protection"
  default     = false
}

variable "enable_rate_limit" {
  type        = bool
  description = "Enable rate limiting"
  default     = false
}

variable "enable_bot_defense" {
  type        = bool
  description = "Enable bot defense"
  default     = false
}