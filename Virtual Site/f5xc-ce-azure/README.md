# F5 Distributed Cloud Customer Edge (CE) on Azure with Dual-NIC NAT Gateway Configuration

This Terraform project deploys F5 Distributed Cloud (F5XC) Customer Edge (CE) nodes on Azure with a dual-NIC configuration using NAT Gateway connectivity. The deployment creates a secure mesh site with both outside (SLO) and inside (SLI) network interfaces, where the outside interface uses a private subnet with NAT Gateway for outbound internet connectivity.

## Architecture Overview

### Key Components

- **Dual-NIC Configuration**: Each F5XC CE node has two network interfaces
  - **Outside Interface (SLO)**: Connected to a private subnet with NAT Gateway for secure outbound connectivity
  - **Inside Interface (SLI)**: Connected to a private subnet for internal/workload traffic
- **Network Security Groups**: 
  - **SLO Network Security Group**: Restrictive rules for management access (HTTP from VNet)
  - **SLI Network Security Group**: Permissive rules for internal traffic
  - **Load Balancer Network Security Group**: Only allows HTTP (80) and HTTPS (443) traffic
- **Azure Load Balancer (Optional)**: Public-facing Azure Load Balancer for traffic distribution across F5XC CE nodes
- **F5XC Integration**: Creates secure mesh sites with token-based authentication
- **Multi-Node Support**: Deploy 1-10 nodes with individual F5XC sites and unique naming
- **Virtual Sites (Optional)**: F5XC virtual site creation with label-based selection
- **HTTP Load Balancer (Optional)**: F5XC HTTP load balancer with direct response capability

### Security Features

- **NAT Gateway**: Provides secure outbound internet access without direct public IP exposure
- **Network Security Group Isolation**: Separate NSGs for different interfaces
- **Load Balancer Security**: Dedicated NSG restricting Load Balancer to HTTP/HTTPS only

## Prerequisites

### Azure Requirements

#### 1. Azure Account and Permissions
- Azure account with appropriate permissions to create:
  - Virtual Machines
  - Network Interfaces
  - Network Security Groups
  - Load Balancers and Public IPs
  - Marketplace VM deployments

#### 2. Existing Azure Infrastructure
**IMPORTANT**: This Terraform configuration requires pre-existing Azure networking infrastructure. See [AZURE-PREREQUISITES.md](AZURE-PREREQUISITES.md) for detailed setup instructions.

Required components:
- Resource Group
- Virtual Network with proper DNS settings
- Subnets (Outside, Inside, Public for Load Balancer)
- NAT Gateway configuration
- Route tables properly configured

#### 3. Azure CLI Setup
Install Azure CLI (if not already installed)
```bash
# Login to Azure
az login

# Set subscription (if multiple subscriptions)
az account set --subscription "Your-Subscription-Name"
```

#### 4. Azure Marketplace Terms
Accept F5XC CE marketplace terms (one-time requirement):
```bash
az vm image terms accept --publisher f5-networks --offer f5xc_customer_edge --plan f5xccebyol
```

### F5 Distributed Cloud Requirements

#### 1. F5XC Tenant Account
- Access to F5 Distributed Cloud console
- Tenant URL (e.g., https://your-tenant.console.ves.volterra.io)

#### 2. API Credentials
1. **Download API Certificate:**
   - Please see this page on the official F5 XC documentation: https://docs.cloud.f5.com/docs-v2/administration/how-tos/user-mgmt/Credentials#generate-api-certificate-for-service-credentials

2. **API URL:**
   - Your tenant-specific API URL: `https://[your-tenant].console.ves.volterra.io/api`

## Quick Start

### 1. Clone and Setup
```bash
git clone <repository-url>
cd f5xc-ce-azure

# Copy example variables file
cp terraform.tfvars.example terraform.tfvars
```

### 2. Configure Variables
Edit `terraform.tfvars` with your specific values:

```hcl
# terraform.tfvars
resource_group_name = "f5xc-rg"
vnet_name          = "f5xc-vnet"
outside_subnet_name = "outside-subnet"
inside_subnet_name  = "inside-subnet"
location           = "West US 2"
ssh_public_key     = "ssh-rsa AAAAB3NzaC1yc2E..."

# F5XC Configuration
f5xc_virtual_site_name     = "azure-prod-vsite"
f5xc_api_url       = "https://your-tenant.console.ves.volterra.io/api"
f5xc_api_p12_file  = "/path/to/api-creds.p12"

# Optional features
deploy_lb                   = true
create_f5xc_virtual_site   = false
create_f5xc_loadbalancer   = false
```

### 3. Deploy
```bash
# Initialize Terraform
terraform init

# Review deployment plan
terraform plan

# Apply configuration
terraform apply
```

# Support and license

This repository contains community code which is not covered by F5 Technical Support nor any SLA.

Please read and understand the [LICENSE](LICENSE) before use. 

The solutions in this repository are not guaranteed to work, keep working or being updated with required changes at any time.

You, as the implementor, are solely responsible.

## Last updated
August 28th 2025