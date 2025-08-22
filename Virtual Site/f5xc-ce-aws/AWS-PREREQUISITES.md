# AWS Prerequisites

This document provides detailed instructions for setting up the required AWS infrastructure before deploying F5XC CE nodes using this Terraform configuration.

## Overview

The F5XC CE deployment requires existing AWS networking infrastructure. This Terraform configuration does **NOT** create VPCs, subnets, or NAT Gateways - these must exist before deployment.

## Required AWS Infrastructure

### Global Architecture Diagram

Please see the [diagram](f5xc-aws.jpeg).

### 1. VPC Configuration

#### Create VPC
You need an existing VPC with appropriate CIDR block and DNS settings.

```bash
# Using AWS CLI
aws ec2 create-vpc \
    --cidr-block 10.0.0.0/16 \
    --enable-dns-hostnames \
    --enable-dns-support \
    --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=my-vpc}]'
```

**VPC Requirements:**
- DNS hostnames and DNS support must be enabled
- Appropriate CIDR block for your network design
- Proper tagging with `Name` tag (used by Terraform)

### 2. Subnet Configuration

You need three types of subnets:

#### A. Public Subnet (for NAT Gateway and optional NLB)
```bash
# Create public subnet
aws ec2 create-subnet \
    --vpc-id vpc-xxxxxxxxx \
    --cidr-block 10.0.1.0/24 \
    --availability-zone us-west-2a \
    --map-public-ip-on-launch \
    --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=my-public-subnet}]'

# Create Internet Gateway
aws ec2 create-internet-gateway \
    --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=my-igw}]'

# Attach Internet Gateway to VPC
aws ec2 attach-internet-gateway \
    --internet-gateway-id igw-xxxxxxxxx \
    --vpc-id vpc-xxxxxxxxx

# Create route table for public subnet
aws ec2 create-route-table \
    --vpc-id vpc-xxxxxxxxx \
    --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=public-rt}]'

# Add route to Internet Gateway
aws ec2 create-route \
    --route-table-id rtb-xxxxxxxxx \
    --destination-cidr-block 0.0.0.0/0 \
    --gateway-id igw-xxxxxxxxx

# Associate route table with public subnet
aws ec2 associate-route-table \
    --subnet-id subnet-xxxxxxxxx \
    --route-table-id rtb-xxxxxxxxx
```

#### B. Outside Subnet (private with NAT Gateway route)
```bash
# Create outside (private) subnet
aws ec2 create-subnet \
    --vpc-id vpc-xxxxxxxxx \
    --cidr-block 10.0.2.0/24 \
    --availability-zone us-west-2a \
    --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=my-outside-subnet}]'
```

#### C. Inside Subnet (private for workloads)
```bash
# Create inside (private) subnet
aws ec2 create-subnet \
    --vpc-id vpc-xxxxxxxxx \
    --cidr-block 10.0.3.0/24 \
    --availability-zone us-west-2a \
    --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=my-inside-subnet}]'
```

### 3. NAT Gateway Configuration

The NAT Gateway provides secure outbound internet access for F5XC CE nodes.

```bash
# Allocate Elastic IP for NAT Gateway
aws ec2 allocate-address \
    --domain vpc \
    --tag-specifications 'ResourceType=elastic-ip,Tags=[{Key=Name,Value=nat-gateway-eip}]'

# Create NAT Gateway in public subnet
aws ec2 create-nat-gateway \
    --subnet-id subnet-public-xxxxxxxxx \
    --allocation-id eipalloc-xxxxxxxxx \
    --tag-specifications 'ResourceType=nat-gateway,Tags=[{Key=Name,Value=my-nat-gateway}]'

# Create route table for outside subnet
aws ec2 create-route-table \
    --vpc-id vpc-xxxxxxxxx \
    --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=outside-rt}]'

# Add route to NAT Gateway for outside subnet
aws ec2 create-route \
    --route-table-id rtb-outside-xxxxxxxxx \
    --destination-cidr-block 0.0.0.0/0 \
    --nat-gateway-id nat-xxxxxxxxx

# Associate route table with outside subnet
aws ec2 associate-route-table \
    --subnet-id subnet-outside-xxxxxxxxx \
    --route-table-id rtb-outside-xxxxxxxxx
```

### 4. SSH Key Pair

Create an EC2 key pair for SSH access to F5XC CE instances.

```bash
# Create key pair
aws ec2 create-key-pair \
    --key-name my-ssh-key \
    --key-type rsa \
    --key-format pem \
    --query 'KeyMaterial' \
    --output text > my-ssh-key.pem

# Set proper permissions
chmod 400 my-ssh-key.pem
```

## Route Table Configuration

### Public Subnet Route Table
| Destination | Target | Purpose |
|-------------|---------|----------|
| 10.0.0.0/16 | local | VPC local traffic |
| 0.0.0.0/0 | igw-xxxxx | Internet access |

### Outside Subnet Route Table
| Destination | Target | Purpose |
|-------------|---------|----------|
| 10.0.0.0/16 | local | VPC local traffic |
| 0.0.0.0/0 | nat-xxxxx | Outbound via NAT Gateway |

### Inside Subnet Route Table
| Destination | Target | Purpose |
|-------------|---------|----------|
| 10.0.0.0/16 | local | VPC local traffic |