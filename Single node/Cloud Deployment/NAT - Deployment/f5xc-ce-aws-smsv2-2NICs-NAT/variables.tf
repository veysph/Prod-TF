variable "vpc_name" {
    type        = string
    description = "The VPC name to deploy resources into"
    default     = "pveys-smsv2-vpc"
}

variable "owner" {
    type        = string
    description = "Creator of the AWS resources (used for resource tagging)"
    default     = "pveys"
}

variable "f5xc_ce_site_name" {
    type        = string
    description = "F5XC Customer Edge site/cluster name for AWS deployment"
    default     = "pveys-smsv2-aws-tf-igw"
}

variable "aws_ssh_key" {
    type        = string
    description = "AWS EC2 Key Pair name for SSH access to the instance"
    default     = "<name of the ssh key in AWS>"
}

variable "aws_region" {
    type        = string
    description = "AWS region for F5XC Customer Edge deployment"
    default     = "eu-west-3"
}

variable "aws_f5xc_ami" {
    type        = string
    description = "F5XC Customer Edge AMI ID to use for deployment"
    default     = "ami-032a3669fe1532f76"
}

variable "aws_ec2_flavor" {
  type        = string
  description = "EC2 instance type (allowed: m5.2xlarge, m5.4xlarge)"
  default = "m5.2xlarge"

  validation {
    condition     = contains(["m5.2xlarge", "m5.4xlarge"], var.aws_ec2_flavor)
    error_message = "Invalid EC2 instance type. Allowed values are: m5.2xlarge or m5.4xlarge."
  }
}

variable "slo_private_ip" {
    type        = string
    description = "Private IP address for SLO (Site Local Outside) interface"
    default     = "<your private IP for SLO>"
}

variable "sli_private_ip" {
    type        = string
    description = "Private IP address for SLI (Site Local Inside) interface"
    default     = "<your private IP for SLI>"
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

variable "outside_subnet_name" {
    type        = string
    description = "Name of the outside/public subnet for SLO interface"
    default     = "pveys-smsv2-public-3a"
}

variable "inside_subnet_name" {
    type        = string
    description = "Name of the inside/private subnet for SLI interface"
    default     = "pveys-smsv2-private-3a"
}