# Variables Documentation

This document provides detailed information about all configurable variables in the F5XC CE Azure Terraform deployment.

## Required Variables

These variables must be configured in your `terraform.tfvars` file or provided via other means.

### Azure Infrastructure Variables

#### `resource_group_name`
- **Type**: `string`
- **Description**: Name of existing Azure Resource Group where F5XC CE nodes will be deployed
- **Default**: `"my-f5xc-rg"`
- **Example**: `"f5xc-prod-rg"`
- **Notes**: Must be an existing Resource Group with proper tags

#### `vnet_name`
- **Type**: `string`
- **Description**: Name of existing Azure Virtual Network
- **Default**: `"my-f5xc-vnet"`
- **Example**: `"production-vnet"`
- **Notes**: Must be an existing VNet with proper address space

#### `outside_subnet_name`
- **Type**: `string`
- **Description**: Name of the outside subnet (private subnet with NAT Gateway for outbound connectivity)
- **Default**: `"outside-subnet"`
- **Example**: `"prod-outside-subnet"`
- **Notes**: 
  - Must be a private subnet
  - Must have route to NAT Gateway for `0.0.0.0/0`
  - Used for F5XC CE outside interface (SLO)

#### `inside_subnet_name`
- **Type**: `string`
- **Description**: Name of the inside/private subnet for internal traffic
- **Default**: `"inside-subnet"`
- **Example**: `"prod-workload-subnet"`
- **Notes**: 
  - Private subnet for internal/workload traffic
  - Used for F5XC CE inside interface (SLI)

#### `lb_public_subnet_name`
- **Type**: `string`
- **Description**: Name of the public subnet for the Azure Load Balancer
- **Default**: `"public-subnet"`
- **Example**: `"prod-public-subnet"`
- **Notes**: 
  - Required only if `deploy_lb = true`
  - Must be a public subnet with Internet Gateway route

#### `location`
- **Type**: `string`
- **Description**: Azure region for F5XC CE deployment
- **Default**: `"West US 2"`
- **Example**: `"East US"`
- **Valid Values**: Any valid Azure region
- **Notes**: Must match the region where your Resource Group/VNet/subnets exist

#### `ssh_username`
- **Type**: `string`
- **Description**: SSH username for Azure VM access
- **Default**: `"adminuser"`
- **Example**: `"cloud-user"`
- **Notes**: Used for SSH access to F5XC CE VMs

#### `ssh_public_key`
- **Type**: `string`
- **Description**: SSH public key for Azure VM access
- **Default**: `""`
- **Example**: `"ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQ..."`
- **Notes**: 
  - Must be in OpenSSH format
  - Used for SSH access to F5XC CE instances

#### `owner`
- **Type**: `string`
- **Description**: Owner tag for Azure resources
- **Default**: `"your-name"`
- **Example**: `"devops-team"`
- **Notes**: Added as a tag to all created Azure resources

### F5XC Configuration Variables

#### `f5xc-ce-site-name`
- **Type**: `string`
- **Description**: F5XC CE site/cluster name (used as prefix for resources)
- **Default**: `"my-f5xc-site"`
- **Example**: `"prod-azure-west"`
- **Notes**: 
  - Used as prefix for all F5XC sites and Azure resources
  - Combined with random suffix for uniqueness
  - Keep short to avoid Azure resource name limits

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

## VM Instance Configuration

#### `f5xc_sms_instance_type`
- **Type**: `string`
- **Description**: Azure VM size for F5XC CE nodes
- **Default**: `"Standard_D8_v4"`
- **Valid Values**: `"Standard_D8_v4"`, `"Standard_D16_v4"`
- **Notes**: 
  - `Standard_D8_v4`: 8 vCPUs, 32 GB RAM (minimum recommended)
  - `Standard_D16_v4`: 16 vCPUs, 64 GB RAM (higher performance)

#### `f5xc_sms_storage_account_type`
- **Type**: `string`
- **Description**: Storage account type for VM disk
- **Default**: `"Standard_LRS"`
- **Valid Values**: `"Standard_LRS"`, `"Premium_LRS"`, `"StandardSSD_LRS"`
- **Notes**: Choose based on performance and cost requirements

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

### Azure Load Balancer

#### `deploy_lb`
- **Type**: `bool`
- **Description**: Deploy Azure Load Balancer
- **Default**: `false`
- **Notes**: 
  - When `true`, creates public-facing Azure Load Balancer
  - Distributes traffic across all F5XC CE nodes
  - Requires `lb_public_subnet_name` to be configured

#### `lb_target_ports`
- **Type**: `list(number)`
- **Description**: Target ports for Load Balancer to forward traffic to F5XC CE nodes
- **Default**: `[80, 443]`
- **Example**: `[80, 443, 8080, 8443]`
- **Notes**: 
  - Creates target groups for each port
  - Traffic forwarded to F5XC CE outside interfaces
  - Only used if `deploy_lb = true`

#### `lb_health_check_port`
- **Type**: `number`
- **Description**: Port for Load Balancer health check
- **Default**: `80`
- **Example**: `8080`
- **Notes**: 
  - Health checks performed against this port
  - Must be a port that responds to TCP connections
  - Only used if `deploy_lb = true`

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
- **Example**: `"azure-west-vsite"`
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
  - Needed when the Azure Load Balancer is deployed to ensure that the TCP healthcheck will be working

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
  - With this deployment it must be `"SITE_NETWORK_OUTSIDE"`

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

### Security Features

#### `enable_waf`
- **Type**: `bool`
- **Description**: Enable Web Application Firewall
- **Default**: `false`
- **Notes**: Enables F5XC WAF protection on the load balancer

#### `enable_rate_limit`
- **Type**: `bool`
- **Description**: Enable rate limiting
- **Default**: `false`
- **Notes**: Enables F5XC rate limiting on the load balancer

#### `enable_bot_defense`
- **Type**: `bool`
- **Description**: Enable bot defense
- **Default**: `false`
- **Notes**: Enables F5XC bot defense on the load balancer

### Internal Variables

#### `f5xc_sms_description`
- **Type**: `string`
- **Description**: Description for F5XC secure mesh site
- **Default**: `"F5XC Azure site created with Terraform"`
- **Notes**: Appears in F5XC console site descriptions

## Variable Validation

The following variables have built-in validation rules:

### `node_count`
```hcl
validation {
  condition     = var.node_count >= 1 && var.node_count <= 10
  error_message = "Node count must be between 1 and 10."
}
```

## Examples

### Full Configuration
```hcl
# terraform.tfvars
# Azure Configuration
resource_group_name = "f5xc-prod-rg"
vnet_name = "production-vnet"
outside_subnet_name = "prod-outside-subnet"
inside_subnet_name = "prod-workload-subnet"
lb_public_subnet_name = "prod-public-subnet"
location = "East US"
ssh_username = "cloud-user"
ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQ..."
owner = "devops-team"

# F5XC Configuration
f5xc-ce-site-name = "prod-azure-east"
node_count = 3
f5xc_api_url = "https://company.console.ves.volterra.io/api"
f5xc_api_p12_file = "/secure/f5xc-api-creds.p12"

# VM Configuration
f5xc_sms_instance_type = "Standard_D16_v4"
f5xc_sms_storage_account_type = "Premium_LRS"

# Azure Load Balancer
deploy_lb = true
lb_target_ports = [80, 443]
lb_health_check_port = 80

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
domains = ["test-hc.hc.local"]

# Security Features
enable_waf = true
enable_rate_limit = true
enable_bot_defense = false
```