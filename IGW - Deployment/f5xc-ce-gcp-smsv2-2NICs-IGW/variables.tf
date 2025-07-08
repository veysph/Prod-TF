variable "vpc_name" {
    description =  "The VPC"
    default = "pveys-smsv2-vpc"
}

variable "f5xc-ce-site-name" {
    description = "AWS CE site/cluster name"
    default = "pveys-smsv2-gcp-tf-1"
}

variable "gcp_region" {
    description = "GCP region for F5XC CE deployment"
    default = "<your region>"
}

variable "gcp_project" {
    description = "GCP project"
    default = "<your project>"
}

variable "slo-private-ip" {
    description = "Private IP for SLO"
    default = "<your private IP on SLO NIC>"
}

variable "sli-private-ip" {
    description = "Private IP for SLI"
    default = "<your private IP on SLI NIC>"
}

variable "ssh_username" {
  type        = string
  description = "ssh user for the F5XC CE"
  default     = "cloud-user"
}

variable "ssh_key" {
  type = string
  default = "<ssh key>"
}

variable "f5xc_api_url" {
  type    = string
  default = "https:/<tenant_name>.console.ves.volterra.io/api"
}

variable "f5xc_api_p12_file" {
  type        = string
  description = "Volterra tenant api key"
  default     = "<location>"
}

variable "f5xc_sms_description" {
  type    = string
  default = "F5XC GCP site smsv2 site created with Terraform"
}