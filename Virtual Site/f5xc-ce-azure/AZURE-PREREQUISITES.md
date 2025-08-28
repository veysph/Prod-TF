# Azure Prerequisites

This document provides detailed instructions for setting up the required Azure infrastructure before deploying F5XC CE nodes using this Terraform configuration.

## Overview

The F5XC CE deployment requires existing Azure networking infrastructure. This Terraform configuration does **NOT** create Virtual Networks, subnets, or NAT Gateways - these must exist before deployment.

## Required Azure Infrastructure

### 1. Resource Group Configuration

#### Create Resource Group
You need an existing Resource Group to contain all resources.

```bash
# Using Azure CLI
az group create \
    --name "f5xc-rg" \
    --location "West US 2" \
    --tags Name=f5xc-rg
```

**Resource Group Requirements:**
- Appropriate location for your deployment
- Proper tagging with `Name` tag (used by Terraform)

### 2. Virtual Network Configuration

#### Create Virtual Network
You need an existing Virtual Network with appropriate address space and DNS settings.

```bash
# Create Virtual Network
az network vnet create \
    --resource-group "f5xc-rg" \
    --name "f5xc-vnet" \
    --address-prefix 10.0.0.0/16 \
    --location "West US 2" \
    --tags Name=f5xc-vnet
```

**Virtual Network Requirements:**
- Appropriate CIDR block for your network design
- Proper tagging with `Name` tag (used by Terraform)

### 3. Subnet Configuration

You need three types of subnets:

#### A. Public Subnet (for NAT Gateway and optional Load Balancer)
```bash
# Create public subnet
az network vnet subnet create \
    --resource-group "f5xc-rg" \
    --vnet-name "f5xc-vnet" \
    --name "public-subnet" \
    --address-prefixes 10.0.1.0/24
```

#### B. Outside Subnet (Private with NAT Gateway route)
```bash
# Create outside subnet (for F5XC CE outside interface - SLO)
az network vnet subnet create \
    --resource-group "f5xc-rg" \
    --vnet-name "f5xc-vnet" \
    --name "outside-subnet" \
    --address-prefixes 10.0.2.0/24
```

#### C. Inside Subnet (Private for workloads)
```bash
# Create inside subnet (for F5XC CE inside interface - SLI)
az network vnet subnet create \
    --resource-group "f5xc-rg" \
    --vnet-name "f5xc-vnet" \
    --name "inside-subnet" \
    --address-prefixes 10.0.3.0/24
```

**Subnet Requirements:**
- **Public Subnet**: Used for NAT Gateway and optional Azure Load Balancer
- **Outside Subnet**: Must be routed through NAT Gateway for outbound internet access
- **Inside Subnet**: Private subnet for internal/workload traffic
- All subnets must have proper tagging with `Name` tag (used by Terraform)

### 4. NAT Gateway Configuration

#### Create Public IP for NAT Gateway
```bash
# Create Public IP for NAT Gateway
az network public-ip create \
    --resource-group "f5xc-rg" \
    --name "nat-gateway-pip" \
    --sku "Standard" \
    --location "West US 2" \
    --tags Name=nat-gateway-pip
```

#### Create NAT Gateway
```bash
# Create NAT Gateway
az network nat gateway create \
    --resource-group "f5xc-rg" \
    --name "f5xc-nat-gateway" \
    --public-ip-addresses "nat-gateway-pip" \
    --idle-timeout 4 \
    --location "West US 2" \
    --tags Name=f5xc-nat-gateway
```

#### Associate NAT Gateway with Outside Subnet
```bash
# Associate NAT Gateway with outside subnet
az network vnet subnet update \
    --resource-group "f5xc-rg" \
    --vnet-name "f5xc-vnet" \
    --name "outside-subnet" \
    --nat-gateway "f5xc-nat-gateway"
```

### 5. Route Table Configuration

Route tables should be automatically configured when associating the NAT Gateway with the outside subnet. However, you can verify and create custom route tables if needed:

#### Outside Subnet Route Table
- **Destination**: 0.0.0.0/0 (Default route)
- **Next Hop**: NAT Gateway
- **Route Type**: User-defined

#### Inside Subnet Route Table
- **Destination**: Local VNet traffic only
- **Next Hop**: Virtual network gateway (if connecting to on-premises)
- **Route Type**: System routes (default)

#### Public Subnet Route Table
- **Destination**: 0.0.0.0/0 (Default route)
- **Next Hop**: Internet Gateway
- **Route Type**: System routes (default)

### 6. SSH Key Configuration

Create an SSH key pair for accessing the F5XC CE VMs:

```bash
# Generate SSH key pair
ssh-keygen -t rsa -b 2048 -f ~/.ssh/f5xc_azure_key

# Set appropriate permissions
chmod 600 ~/.ssh/f5xc_azure_key
chmod 644 ~/.ssh/f5xc_azure_key.pub

# Display public key (copy this for terraform.tfvars)
cat ~/.ssh/f5xc_azure_key.pub
```

### 7. Azure Marketplace Terms

Accept the F5XC CE marketplace terms (one-time requirement):

```bash
# Accept marketplace terms for F5XC CE
az vm image terms accept --publisher f5-networks --offer f5xc_customer_edge --plan f5xccebyol
```

## Network Architecture Summary

After completing the prerequisites, your Azure network architecture will look like this:

```
Azure Resource Group: f5xc-rg
├── Virtual Network: f5xc-vnet (10.0.0.0/16)
│   ├── Public Subnet: public-subnet (10.0.1.0/24)
│   │   └── Route: 0.0.0.0/0 → Internet
│   │   └── Used for: NAT Gateway, Load Balancer
│   ├── Outside Subnet: outside-subnet (10.0.2.0/24)
│   │   └── Route: 0.0.0.0/0 → NAT Gateway
│   │   └── Used for: F5XC CE Outside Interface (SLO)
│   └── Inside Subnet: inside-subnet (10.0.3.0/24)
│       └── Route: Local VNet only
│       └── Used for: F5XC CE Inside Interface (SLI)
└── NAT Gateway: f5xc-nat-gateway
    └── Public IP: nat-gateway-pip
```

## Troubleshooting

### Common Issues

1. **Marketplace Terms Not Accepted**
   ```bash
   # Re-accept terms if needed
   az vm image terms accept --publisher f5-networks --offer f5xc_customer_edge --plan f5xccebyol
   ```

## Next Steps

After completing these prerequisites:

1. Update `terraform.tfvars` with your Azure resource names
2. Proceed with the F5XC CE Terraform deployment
3. Verify F5XC site registration in the F5XC console

For deployment instructions, see [README.md](README.md).