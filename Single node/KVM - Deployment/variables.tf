variable "f5xc_api_url" {
  type    = string
  default = "https://<tenant>.console.ves.volterra.io/api"
}

variable "f5xc_api_p12_file" {
  type        = string
  description = "F5XC tenant api key"
  default     = "<location of your tenant API key>"
}

variable "f5xc_sms_description" {
  type    = string
  default = "F5XC KVM site smsv2 site created with Terraform"
}

variable "f5xc-ce-qcow2" {
    description = "KVM CE QCOW2 image source"
    default = "<location of the F5XC CE QCOW2 image"
}

variable "f5xc-ce-memory" {
    description = "Memory allocated to KVM CE"
    default = "32000"
}

variable "f5xc-ce-vcpu" {
    description = "Number of vCPUs allocated to KVM CE"
    default = "8"
}

variable "f5xc-ce-site-name" {
    description = "KVM CE site/cluster name"
    default = "pveys-smsv2-kvm"
}

variable "f5xc-ce-node-name" {
    description = "KVM CE node name"
    default = "node-0"
}

variable "f5xc-ce-storage-pool" {
    description = "KVM CE storage pool name"
    default = "<your storage pool>"
}

variable "f5xc-ce-network-slo" {
    description = "KVM Networking for SLO interface"
    default = "<your kvm networking for SLO>"
}

variable "f5xc-ce-network-sli" {
    description = "KVM Networking for SLI interface"
    default = "<your KVM networking for SLI>"
} 
