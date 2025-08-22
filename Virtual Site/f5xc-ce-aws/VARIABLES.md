# Variables Documentation

This document provides detailed information about all configurable variables in the F5XC CE AWS Terraform deployment.

## Required Variables

These variables must be configured in your `terraform.tfvars` file or provided via other means.

### AWS Infrastructure Variables

#### `vpc_name`
- **Type**: `string`
- **Description**: The name of the existing AWS VPC where F5XC CE nodes will be deployed
- **Default**: `"my-vpc"`
- **Example**: `"production-vpc"`
- **Notes**: Must be an existing VPC with proper tags

#### `outside_subnet_name`  
- **Type**: `string`
- **Description**: Name of the outside subnet (private subnet with NAT Gateway for outbound connectivity)
- **Default**: `"my-outside-subnet"`
- **Example**: `"prod-private-subnet-1a"`
- **Notes**: 
  - Must be a private subnet
  - Must have route to NAT Gateway for `0.0.0.0/0`
  - Used for F5XC CE outside interface (SLO)

#### `inside_subnet_name`
- **Type**: `string`  
- **Description**: Name of the inside/private subnet for internal traffic
- **Default**: `"my-inside-subnet"`
- **Example**: `"prod-workload-subnet-1a"`
- **Notes**: 
  - Private subnet for internal/workload traffic
  - Used for F5XC CE inside interface (SLI)

#### `nlb_public_subnet_name`
- **Type**: `string`
- **Description**: Name of the public subnet for the Network Load Balancer
- **Default**: `"my-public-subnet"`  
- **Example**: `"prod-public-subnet-1a"`
- **Notes**: 
  - Required only if `deploy_nlb = true`
  - Must be a public subnet with Internet Gateway route

#### `aws_region`
- **Type**: `string`
- **Description**: AWS region for F5XC CE deployment
- **Default**: `"us-west-2"`
- **Example**: `"us-east-1"`
- **Valid Values**: Any valid AWS region
- **Notes**: Must match the region where your VPC/subnets exist

#### `aws_ssh_key`
- **Type**: `string`
- **Description**: AWS SSH key pair name for EC2 instance access
- **Default**: `"my-ssh-key"`
- **Example**: `"production-keypair"`
- **Notes**: 
  - Must be an existing EC2 key pair in the specified region
  - Used for SSH access to F5XC CE instances

#### `aws_f5xc_ami`
- **Type**: `string`
- **Description**: F5XC CE AMI ID (obtain from F5 Distributed Cloud console)
- **Default**: `"ami-xxxxxxxxxxxxxxxxx"`
- **Example**: `"ami-0123456789abcdef0"`
- **Notes**: 
  - Obtain latest AMI ID with:
  ```bash
  aws ec2 describe-images \
  --region eu-west-3 \
  --filters "Name=name,Values=*f5xc-ce*" \
  --query "reverse(sort_by(Images, &CreationDate))[*].{ImageId:ImageId,Name:Name,CreationDate:CreationDate}" \
  --output table
  ```


#### `owner`
- **Type**: `string`
- **Description**: Owner tag for AWS resources
- **Default**: `"your-name"`
- **Example**: `"devops-team"`
- **Notes**: Added as a tag to all created AWS resources

### F5XC Configuration Variables

#### `f5xc_ce_site_name`
- **Type**: `string`
- **Description**: F5XC CE site/cluster name (used as prefix for resources)
- **Default**: `"my-f5xc-site"`
- **Example**: `"prod-aws-east"`
- **Notes**: 
  - Used as prefix for all F5XC sites and AWS resources
  - Combined with random suffix for uniqueness
  - Keep short to avoid AWS resource name limits

#### `f5xc_api_url`
- **Type**: `string`
- **Description**: F5XC API endpoint URL
- **Default**: `"https://your-tenant.console.ves.volterra.io/api"`
- **Example**: `"https://my-company.console.ves.volterra.io/api"`
- **Notes**: 
  - Replace `your-tenant` with your actual F5XC tenant name
  - URL format is standardized across tenants

#### `f5xc_api_p12_file`
- **Type**: `string`
- **Description**: Path to F5XC API credentials P12 file
- **Default**: `"/path/to/your/api-creds.p12"`
- **Example**: `"/home/user/.f5xc/api-creds.p12"`
- **Notes**: 
  - Download from F5XC console (Administration → Credentials)
  - Must be readable by Terraform execution environment
  - Keep secure and do not commit to version control

## EC2 Instance Configuration

#### `aws_ec2_flavor`
- **Type**: `string`
- **Description**: EC2 instance type for F5XC CE nodes
- **Default**: `"m5.2xlarge"`
- **Valid Values**: `"m5.2xlarge"`, `"m5.4xlarge"`
- **Validation**: Only these two instance types are supported
- **Notes**: 
  - `m5.2xlarge`: 8 vCPUs, 32 GB RAM (minimum recommended)
  - `m5.4xlarge`: 16 vCPUs, 64 GB RAM (higher performance)

#### `node_count`
- **Type**: `number`
- **Description**: Number of F5XC CE nodes to deploy
- **Default**: `1`
- **Range**: 1-10
- **Validation**: Must be between 1 and 10
- **Notes**:
  - Each node gets unique naming with suffix
  - Each node creates separate F5XC site

## Optional Features

### Network Load Balancer

#### `deploy_nlb`
- **Type**: `bool`
- **Description**: Deploy AWS Network Load Balancer
- **Default**: `false`
- **Notes**: 
  - When `true`, creates public-facing NLB
  - Distributes traffic across all F5XC CE nodes
  - Requires `nlb_public_subnet_name` to be configured

#### `nlb_target_ports`
- **Type**: `list(number)`
- **Description**: Target ports for NLB to forward traffic to F5XC CE nodes
- **Default**: `[80, 443]`
- **Example**: `[80, 443, 8080, 8443]`
- **Notes**: 
  - Creates target groups for each port
  - Traffic forwarded to F5XC CE outside interfaces
  - Only used if `deploy_nlb = true`

#### `nlb_health_check_port`
- **Type**: `number`
- **Description**: Port for NLB health check
- **Default**: `80`
- **Example**: `8080`
- **Notes**: 
  - Health checks performed against this port
  - Must be a port that responds to TCP connections
  - Only used if `deploy_nlb = true`

### F5XC Virtual Site

#### `create_f5xc_vsite_resources`
- **Type**: `bool`
- **Description**: Create F5XC virtual site key and label resources
- **Default**: `true`
- **Notes**: 
  - Creates labels on F5XC sites for virtual site selection
  - Required for virtual site functionality

#### `f5xc_vsite_key`
- **Type**: `string`
- **Description**: F5XC virtual site key for site selection
- **Default**: `"my-vsite-key"`
- **Example**: `"environment"`
- **Notes**: 
  - Label key applied to F5XC sites
  - Used by virtual sites to select member sites

#### `f5xc_vsite_key_label`
- **Type**: `string`
- **Description**: F5XC virtual site key label value
- **Default**: `"yes"`
- **Example**: `"production"`
- **Notes**: 
  - Label value applied to F5XC sites
  - Virtual sites select sites with matching key/value pairs

#### `create_f5xc_virtual_site`
- **Type**: `bool`
- **Description**: Create F5XC Virtual Site
- **Default**: `false`
- **Notes**: 
  - When `true`, creates a virtual site that includes deployed CE sites
  - Virtual site name must be provided via `f5xc_virtual_site_name`

#### `f5xc_virtual_site_name`
- **Type**: `string`
- **Description**: F5XC Virtual Site name
- **Default**: `""`
- **Example**: `"aws-east-vsite"`
- **Notes**: 
  - Required if `create_f5xc_virtual_site = true`
  - Must be unique within F5XC tenant

### F5XC HTTP Load Balancer

#### `create_f5xc_loadbalancer`
- **Type**: `bool`
- **Description**: Create F5XC HTTP Load Balancer
- **Default**: `false`
- **Notes**: 
  - Creates F5XC HTTP load balancer with direct response
  - Needed when the NLB is deployed to ensure that the TCP healthcheck will be working

#### `lb_name`
- **Type**: `string`
- **Description**: F5XC HTTP Load balancer name
- **Default**: `""`
- **Example**: `"test-lb"`
- **Notes**: 
  - Required if `create_f5xc_loadbalancer = true`
  - Must be unique within F5XC tenant/namespace

#### `namespace`
- **Type**: `string`
- **Description**: F5XC namespace for resources
- **Default**: `"shared"`
- **Example**: `"production"`
- **Notes**: 
  - F5XC namespace where load balancer will be created
  - Namespace must exist in F5XC tenant

#### `domains`
- **Type**: `list(string)`
- **Description**: Domain names for the F5XC HTTP load balancer
- **Default**: `[]`
- **Example**: `["test-hc.hc.local"]`
- **Notes**: 
  - Domain that the healthcheck load balancer will be configured with


#### `http_port`
- **Type**: `number`
- **Description**: HTTP port for the F5XC load balancer
- **Default**: `80`
- **Example**: `80`

#### `virtual_site_network`
- **Type**: `string`
- **Description**: Virtual site network type
- **Default**: `"SITE_NETWORK_OUTSIDE"`
- **Valid Values**: `"SITE_NETWORK_OUTSIDE"`, `"SITE_NETWORK_INSIDE"`
- **Notes**: 
  - With this deployment it must be `"SITE_NETWORK_INSIDE"`

#### `virtual_site_namespace`
- **Type**: `string`
- **Description**: Virtual site namespace
- **Default**: `"shared"`

#### `response_code`
- **Type**: `number`
- **Description**: HTTP response code for direct response
- **Default**: `200`
- **Example**: `200`

#### `response_body`
- **Type**: `string`
- **Description**: HTTP response body for direct response
- **Default**: `"HC OK"`
- **Example**: `"Service Available"`

### Internal Variables

#### `f5xc_sms_description`
- **Type**: `string`
- **Description**: Description for F5XC secure mesh site
- **Default**: `"F5XC AWS site created with Terraform"`
- **Notes**: Appears in F5XC console site descriptions

## Variable Validation

The following variables have built-in validation rules:

### `aws_ec2_flavor`
```hcl
validation {
  condition     = contains(["m5.2xlarge", "m5.4xlarge"], var.aws_ec2_flavor)
  error_message = "Invalid EC2 instance type. Allowed values are: m5.2xlarge or m5.4xlarge."
}
```

### `node_count`  
```hcl
validation {
  condition     = var.node_count >= 1 && var.node_count <= 10
  error_message = "Node count must be between 1 and 10."
}
```

## Examples

### Minimal Configuration
```hcl
# terraform.tfvars
vpc_name = "my-production-vpc"
outside_subnet_name = "private-subnet-1a"
inside_subnet_name = "workload-subnet-1a"
aws_region = "us-west-2"
aws_ssh_key = "my-keypair"
aws_f5xc_ami = "ami-0123456789abcdef0"
f5xc_api_p12_file = "/home/user/.f5xc/api-creds.p12"
```

### Full Configuration with All Features
```hcl
# terraform.tfvars
# AWS Configuration
vpc_name = "production-vpc"
outside_subnet_name = "prod-private-1a"
inside_subnet_name = "prod-workload-1a"  
nlb_public_subnet_name = "prod-public-1a"
aws_region = "us-east-1"
aws_ssh_key = "prod-keypair"
aws_f5xc_ami = "ami-0123456789abcdef0"
aws_ec2_flavor = "m5.4xlarge"
owner = "devops-team"

# F5XC Configuration
f5xc_ce_site_name = "prod-aws-east"
node_count = 3
f5xc_api_url = "https://company.console.ves.volterra.io/api"
f5xc_api_p12_file = "/secure/f5xc-api-creds.p12"

# Network Load Balancer
deploy_nlb = true
nlb_target_ports = [80, 443]
nlb_health_check_port = 80

# Virtual Site
create_f5xc_vsite_resources = true
f5xc_vsite_key = "environment"
f5xc_vsite_key_label = "production"
create_f5xc_virtual_site = true
f5xc_virtual_site_name = "prod-east-vsite"

# HTTP Load Balancer
create_f5xc_loadbalancer = true
lb_name = "prod-hc-lb"
namespace = "production"
domains = ["test-hs.hc.local"]
```