variable "f5xc_api_url" {
  type        = string
  description = "F5XC API URL for the tenant"
  default     = "https://<tenant>.console.ves.volterra.io/api"
}

variable "f5xc_api_p12_file" {
  type        = string
  description = "Path to F5XC tenant P12 certificate file"
  default     = "<location of your tenant API key>"
  sensitive   = true
}

variable "f5xc_sms_description" {
  type        = string
  description = "Description for the F5XC SMS site"
  default     = "F5XC KVM site smsv2 site created with Terraform"
}

variable "f5xc-ce-qcow2" {
    type        = string
    description = "KVM CE QCOW2 image source"
    default     = "<location of the F5XC CE QCOW2 image>"
}

variable "f5xc-ce-memory" {
    type        = number
    description = "Memory allocated to KVM CE in MB"
    default     = 32000
}

variable "f5xc-ce-vcpu" {
    type        = number
    description = "Number of vCPUs allocated to KVM CE"
    default     = 8
}

variable "f5xc-ce-site-name" {
    type        = string
    description = "KVM CE site/cluster name"
    default     = "pveys-smsv2-kvm"
}

variable "f5xc-ce-node-name" {
    type        = string
    description = "KVM CE node name"
    default     = "node-0"
}

variable "f5xc-ce-storage-pool" {
    type        = string
    description = "KVM CE storage pool name"
    default     = "<your storage pool>"
}

variable "f5xc-ce-network-slo" {
    type        = string
    description = "KVM Networking for SLO interface"
    default     = "<your kvm networking for SLO>"
}

variable "f5xc-ce-network-sli" {
    type        = string
    description = "KVM Networking for SLI interface"
    default     = "<your KVM networking for SLI>"
}

variable "f5xc_software_version" {
  type        = string
  description = "F5XC software version for the site (only specify if default_sw_version is false)"
  default     = null
}

variable "f5xc_default_sw_version" {
  type        = bool
  description = "Use default software version (true) or specify custom version (false). If true, volterra_software_version must not be specified"
  default     = true

  validation {
    condition     = can(var.f5xc_default_sw_version)
    error_message = "f5xc_default_sw_version must be a boolean value."
  }
}
