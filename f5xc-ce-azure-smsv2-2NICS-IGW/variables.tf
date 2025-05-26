variable "owner" {
    description = "Creator of the Azure ressources"
    default=  "pveys"
}

variable "f5xc-ce-site-name" {
    description = "Azure CE site/cluster name"
    default = "pveys-smsv2-azure-tf"
}

variable "f5xc_enable_ce_site_ha" {
  type = bool
  default = false
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
  description = "Specifies the size of the virtual machine."
  type        = string
  default     = "Standard_B4as_v2"
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
    description = "<private IP for SLO NIC>"
    default = "10.168.3.250"
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