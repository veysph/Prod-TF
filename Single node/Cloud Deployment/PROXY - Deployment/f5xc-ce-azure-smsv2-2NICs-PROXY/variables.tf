variable "owner" {
    description = "Creator of the Azure ressources"
    default=  "pveys"
}

variable "f5xc-ce-site-name" {
    description = "Azure CE site/cluster name"
    default = "pveys-smsv2-azure-tf"
}

variable "vnet" {
    description = "VNET of the CEs"
    default = "<your VNET>"
}

variable "ressource_group" {
    description = "Azure ressource group"
    default = "<your ressource group>"
}

variable "ssh_key" {
  type = string
  default = "<your ssh key>"
}

variable "ssh_username" {
  type        = string
  description = "ssh user for the F5XC CE"
  default     = "cloud-user"
}

variable "outside-subnet-name" {
    default = "pveys-smsv2-public"
}

variable "inside-subnet-name" {
    default = "pveys-smsv2-private"
}

variable "f5xc_sms_instance_type" {
  description = "Azure instance type (allowed: Standard_D8_v4, Standard_D16_v4)"
  type        = string
  default     = "Standard_D8_v4"

  validation {
    condition     = contains(["Standard_D8_v4", "Standard_D16_v4"], var.f5xc_sms_instance_type)
    error_message = "Invalid Azure instance type. Allowed values are: Standard_D8_v4 or Standard_D16_v4."
  }
}

variable "f5xc_sms_storage_account_type" {
  description = "Defines the type of storage account to be created. Valid options are Standard_LRS, Standard_ZRS, Standard_GRS, Standard_RAGRS, Premium_LRS."
  default     = "Standard_LRS"
}

variable "location" {
  description = "Azure location name"
  default     = "francecentral"
}

variable "slo-private-ip" {
    description = "Private IP for SLO"
    default = "<private IP for SLO NIC>"
}

variable "sli-private-ip" {
    description = "Private IP for SLI"
    default = "<private IP for SLI NIC>"
}

variable "f5xc_api_url" {
  type    = string
  default = "https://<tenant_name>.console.ves.volterra.io/api"
}

variable "f5xc_api_p12_file" {
  type        = string
  description = "Volterra tenant api key"
  default     = "<location>"
}

variable "f5xc_sms_description" {
  type    = string
  default = "F5XC Azure site smsv2 site created with Terraform"
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
    condition     = var.f5xc_default_sw_version == true ? var.f5xc_software_version == null : var.f5xc_software_version != null
    error_message = "When default_sw_version is true, f5xc_software_version must not be specified. When default_sw_version is false, f5xc_software_version must be specified."
  }
}