# F5 Distributed Cloud Customer Edge (CE) on AWS with Dual-NIC NAT Gateway Configuration

This Terraform project deploys F5 Distributed Cloud (F5XC) Customer Edge (CE) nodes on AWS with a dual-NIC configuration using NAT Gateway connectivity. The deployment creates a secure mesh site with both outside (SLO) and inside (SLI) network interfaces, where the outside interface uses a private subnet with NAT Gateway for outbound internet connectivity.

## Architecture Overview

### Key Components

- **Dual-NIC Configuration**: Each F5XC CE node has two network interfaces
  - **Outside Interface (SLO)**: Connected to a private subnet with NAT Gateway for secure outbound connectivity
  - **Inside Interface (SLI)**: Connected to a private subnet for internal/workload traffic
- **Network Load Balancer (Optional)**: Public-facing AWS NLB for traffic distribution across F5XC CE nodes
- **F5XC Integration**: Creates secure mesh sites with token-based authentication
- **Multi-Node Support**: Deploy 1-10 nodes with individual F5XC sites and unique naming
- **Virtual Sites (Optional)**: F5XC virtual site creation with label-based selection
- **HTTP Load Balancer (Optional)**: F5XC HTTP load balancer with direct response capability

### Global Architecture

Please see the [diagram](f5xc-aws.jpeg).

### Security Features

- **NAT Gateway**: Provides secure outbound internet access without direct public IP exposure
- **Security Group Isolation**: Separate security groups for different interfaces
- **NLB Security**: Dedicated security group restricting NLB to HTTP/HTTPS only

## Prerequisites

### AWS Requirements

#### 1. AWS Account and Permissions
- AWS account with appropriate permissions to create:
  - VPC, Subnets, Security Groups
  - EC2 instances, Network Interfaces
  - Network Load Balancer (if enabled)
  - IAM roles and policies (if needed)

#### 2. Existing AWS Infrastructure
You must have the following AWS resources already created:

**VPC and Subnets:**
- **VPC**: A VPC where F5XC CE nodes will be deployed
- **Outside Subnet**: Private subnet with route to NAT Gateway for outbound connectivity
- **Inside Subnet**: Private subnet for internal/workload traffic
- **Public Subnet**: Public subnet for Network Load Balancer (if `deploy_nlb = true`)

**NAT Gateway:**
- NAT Gateway must be deployed in a public subnet
- Route table for the outside subnet must route `0.0.0.0/0` to the NAT Gateway

**SSH Key Pair:**
- EC2 Key Pair for SSH access to F5XC CE instances

**Please have a look at [this document](AWS-PREREQUISITES.md). It contains all the aws cli commands needed to create the basic AWS infrastructure if needed.**

### F5 Distributed Cloud Requirements

#### 1. F5XC Account
- Active F5 Distributed Cloud account
- Access to F5XC console

#### 2. API Credentials
1. **Download API Certificate:**
   - Please see this page on the official F5 XC documentation: https://docs.cloud.f5.com/docs-v2/administration/how-tos/user-mgmt/Credentials#generate-api-certificate-for-service-credentials

2. **API URL:**
   - Your tenant-specific API URL: `https://[your-tenant].console.ves.volterra.io/api`

#### 3. F5XC CE AMI
1. **Obtain AMI ID:**
```bash
  aws ec2 describe-images \
  --region eu-west-3 \
  --filters "Name=name,Values=*f5xc-ce*" \
  --query "reverse(sort_by(Images, &CreationDate))[*].{ImageId:ImageId,Name:Name,CreationDate:CreationDate}" \
  --output table
```


## Quick Start

### 1. Clone and Setup
```bash
# Clone the repository
git clone <repository-url>
cd f5xc-ce-aws

# Copy example variables file
cp terraform.tfvars.example terraform.tfvars
```

### 2. Configure Variables
Edit `terraform.tfvars` with your specific values:

```hcl
# AWS Configuration
vpc_name                = "your-vpc-name"
outside_subnet_name     = "your-outside-subnet-name"
inside_subnet_name      = "your-inside-subnet-name"
nlb_public_subnet_name  = "your-public-subnet-name"
aws_region              = "your-aws-region"
aws_ssh_key             = "your-ssh-key-name"
aws_f5xc_ami            = "ami-xxxxxxxxxxxxxxxxx"
owner                   = "your-name"

# F5XC Configuration
f5xc_ce_site_name       = "your-site-name"
f5xc_api_url            = "https://your-tenant.console.ves.volterra.io/api"
f5xc_api_p12_file       = "/path/to/your/api-creds.p12"

# Optional features
deploy_nlb              = true
create_f5xc_virtual_site = false
create_f5xc_loadbalancer = false
```

### 3. Deploy
```bash
# Initialize Terraform
terraform init

# Review the deployment plan
terraform plan

# Deploy the infrastructure
terraform apply
```
# Support and license

This repository contains community code which is not covered by F5 Technical Support nor any SLA.

Please read and understand the [LICENSE](LICENSE) before use. 

The solutions in this repository are not guaranteed to work, keep working or being updated with required changes at any time.

You, as the implementor, are solely responsible.


## Last updated
August 28th 2025