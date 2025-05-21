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
    default = "<name of the ssh key in AWS>"
}

variable "aws-region" {
    description = "AWS region for F5XC CE deployment"
    default = "eu-west-3"
}

variable "slo-private-ip" {
    description = "Private IP for SLO"
    default = "<your private IP for SLO"
}

variable "sli-private-ip" {
    description = "Private IP for SLI"
    default = "<your private IP for SLI>"
}

variable "f5xc_api_url" {
  type    = string
  default = "https://<tenant name>.console.ves.volterra.io/api"
}

variable "f5xc_api_p12_file" {
  type        = string
  description = "Volterra tenant api key"
  default     = "<location of the api key>"
}

variable "f5xc_sms_description" {
  type    = string
  default = "F5XC SMSv2 AWS site created with Terraform"
}