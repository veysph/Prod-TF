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

variable "aws-f5xc-ami" {
    description = "AMI to use to deploy the F5XC CE"
    default = "ami-032a3669fe1532f76"
}

variable "aws-ec2-flavor" {
  type        = string
  description = "EC2 instance type (allowed: m5.2xlarge, m5.4xlarge)"
  default = "m5.2xlarge"

  validation {
    condition     = contains(["m5.2xlarge", "m5.4xlarge"], var.aws-ec2-flavor)
    error_message = "Invalid EC2 instance type. Allowed values are: m5.2xlarge or m5.4xlarge."
  }
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

variable "aws_shared_config_files" {
  type        = list(string)
  description = "List of paths to AWS shared config files"
  default     = ["~/.aws/config"]
}

variable "aws_shared_credentials_files" {
  type        = list(string)
  description = "List of paths to AWS shared credentials files"
  default     = ["~/.aws/credentials"]
}

variable "aws_profile" {
  type        = string
  description = "AWS profile to use"
  default     = "default"
}

variable "public_subnet_name" {
  type        = string
  description = "Name of the public subnet for SLO interface"
  default     = "pveys-smsv2-public-3a"
}

variable "private_subnet_name" {
  type        = string
  description = "Name of the private subnet for SLI interface"
  default     = "pveys-smsv2-private-3a"
}

variable "proxy_ip_address" {
  type        = string
  description = "Proxy IP address for F5XC custom proxy configuration"
}

variable "proxy_port" {
  type        = number
  description = "Proxy port for F5XC custom proxy configuration"
}