variable "vpc_name" {
    description =  "The VPC"
    default = "pveys-smsv2-vpc"
}

variable "owner" {
    description = "Creator of the AWS ressources"
    default=  "pveys"
}

variable "f5xc-ce-site-name" {
    description = "AWS CE site/cluster name"
    default = "pveys-smsv2-aws-tf-igw"
}

variable "aws-ssh-key" {
    description = "AWS ssh key for the AMI"
    default = "pveys-eu-west-3"
}

variable "aws-region" {
    description = "AWS region for F5XC CE deployment"
    default = "eu-west-3"
}

variable "slo-private-ip" {
    description = "Private IP for SLO"
    default = "10.154.1.25"
}

variable "sli-private-ip" {
    description = "Private IP for SLI"
    default = "10.154.33.250"
}

variable "f5xc_api_url" {
  type    = string
  default = "https://volt-field.console.ves.volterra.io/api"
}

variable "f5xc_api_p12_file" {
  type        = string
  description = "Volterra tenant api key"
  default     = "/Users/p.veys/volt-field.console.ves.volterra.io.api-creds.p12"
}

variable "f5xc_sms_description" {
  type    = string
  default = "F5XC AWS site smsv2 site created with Terraform"
}