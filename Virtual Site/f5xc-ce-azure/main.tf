# Random generator
resource "random_id" "suffix" {
  byte_length = 2
}

# Get Azure Resource Group and Virtual Network
data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

data "azurerm_virtual_network" "main" {
  name                = var.vnet_name
  resource_group_name = data.azurerm_resource_group.main.name
}

data "azurerm_subnet" "outside" {
  name                 = var.outside_subnet_name
  virtual_network_name = data.azurerm_virtual_network.main.name
  resource_group_name  = data.azurerm_resource_group.main.name
}

data "azurerm_subnet" "inside" {
  name                 = var.inside_subnet_name
  virtual_network_name = data.azurerm_virtual_network.main.name
  resource_group_name  = data.azurerm_resource_group.main.name
}

data "azurerm_subnet" "lb_public" {
  name                 = var.lb_public_subnet_name
  virtual_network_name = data.azurerm_virtual_network.main.name
  resource_group_name  = data.azurerm_resource_group.main.name
}

# Azure Network Security Group for outside interface (SLO)
resource "azurerm_network_security_group" "ce_nsg_slo" {
  name                = format("%s-%s-%s", var.f5xc-ce-site-name, random_id.suffix.hex, "nsg-slo")
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name

  security_rule {
    name                       = "HTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = data.azurerm_virtual_network.main.address_space[0]
    destination_address_prefix = "*"
  }

  tags = {
    Name  = format("%s-%s-%s", var.f5xc-ce-site-name, random_id.suffix.hex, "nsg-slo")
    owner = var.owner
  }
}

# Azure Network Security Group for inside interface (SLI)
resource "azurerm_network_security_group" "ce_nsg_sli" {
  name                = format("%s-%s-%s", var.f5xc-ce-site-name, random_id.suffix.hex, "nsg-sli")
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name

  security_rule {
    name                       = "AllowAll"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    Name  = format("%s-%s-%s", var.f5xc-ce-site-name, random_id.suffix.hex, "nsg-sli")
    owner = var.owner
  }
}

# CE Network Interfaces creation - Outside interface (private - using NAT Gateway for outbound)
resource "azurerm_network_interface" "outside" {
  count               = var.node_count
  name                = format("%s-%s-%s-%02d", var.f5xc-ce-site-name, random_id.suffix.hex, "nic-outside", count.index + 1)
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.outside.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    Name  = format("%s-%s-%s-%02d", var.f5xc-ce-site-name, random_id.suffix.hex, "nic-outside", count.index + 1)
    owner = var.owner
  }
}

# Network Security Group Association - Outside
resource "azurerm_network_interface_security_group_association" "outside" {
  count                     = var.node_count
  network_interface_id      = azurerm_network_interface.outside[count.index].id
  network_security_group_id = azurerm_network_security_group.ce_nsg_slo.id
}

# CE Network Interfaces creation - Inside interface (private)
resource "azurerm_network_interface" "inside" {
  count               = var.node_count
  name                = format("%s-%s-%s-%02d", var.f5xc-ce-site-name, random_id.suffix.hex, "nic-inside", count.index + 1)
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.inside.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    Name  = format("%s-%s-%s-%02d", var.f5xc-ce-site-name, random_id.suffix.hex, "nic-inside", count.index + 1)
    owner = var.owner
  }
}

# Network Security Group Association - Inside
resource "azurerm_network_interface_security_group_association" "inside" {
  count                     = var.node_count
  network_interface_id      = azurerm_network_interface.inside[count.index].id
  network_security_group_id = azurerm_network_security_group.ce_nsg_sli.id
}

# Create the F5XC CE Azure Virtual Machine resources
resource "azurerm_linux_virtual_machine" "f5xc_ce" {
  count               = var.node_count
  depends_on          = [azurerm_network_security_group.ce_nsg_sli]
  name                = format("%s-%s-%02d", var.f5xc-ce-site-name, random_id.suffix.hex, count.index + 1)
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name
  size                = var.f5xc_sms_instance_type
  admin_username      = var.ssh_username

  disable_password_authentication = true

  network_interface_ids = [
    azurerm_network_interface.outside[count.index].id,
    azurerm_network_interface.inside[count.index].id,
  ]

  admin_ssh_key {
    username   = var.ssh_username
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = var.f5xc_sms_storage_account_type
    disk_size_gb         = 80
  }

  source_image_reference {
    publisher = "volterraedgeservices"
    offer     = "volterra-node"
    sku       = "volterra-node"
    version   = "latest"
  }

  plan {
    name      = "volterra-node"
    product   = "volterra-node"
    publisher = "volterraedgeservices"
  }

  custom_data = base64encode(data.cloudinit_config.f5xc_ce_config[count.index].rendered)

  tags = {
    Name                                         = format("%s-%s-%02d", var.f5xc-ce-site-name, random_id.suffix.hex, count.index + 1)
    ves-io-site-name                             = format("%s-%s-%02d", var.f5xc-ce-site-name, random_id.suffix.hex, count.index + 1)
    "kubernetes.io/cluster/${var.f5xc-ce-site-name}-${random_id.suffix.hex}-${format("%02d", count.index + 1)}" = "owned"
    owner = var.owner
  }
}

# Network Security Group for Load Balancer
resource "azurerm_network_security_group" "lb_nsg" {
  count               = var.deploy_lb ? 1 : 0
  name                = format("%s-%s-lb-nsg", var.f5xc-ce-site-name, random_id.suffix.hex)
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name

  security_rule {
    name                       = "HTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTPS"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    Name  = format("%s-%s-lb-nsg", var.f5xc-ce-site-name, random_id.suffix.hex)
    owner = var.owner
  }
}

# Azure Load Balancer (equivalent to AWS NLB)
resource "azurerm_public_ip" "lb_pip" {
  count               = var.deploy_lb ? 1 : 0
  name                = format("%s-%s-lb-pip", var.f5xc-ce-site-name, random_id.suffix.hex)
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    Name  = format("%s-%s-lb-pip", var.f5xc-ce-site-name, random_id.suffix.hex)
    owner = var.owner
  }
}

resource "azurerm_lb" "lb" {
  count               = var.deploy_lb ? 1 : 0
  name                = format("%s-%s-lb", var.f5xc-ce-site-name, random_id.suffix.hex)
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.lb_pip[0].id
  }

  tags = {
    Name  = format("%s-%s-lb", var.f5xc-ce-site-name, random_id.suffix.hex)
    owner = var.owner
  }
}

resource "azurerm_lb_backend_address_pool" "lb_backend_pool" {
  count           = var.deploy_lb ? length(var.lb_target_ports) : 0
  loadbalancer_id = azurerm_lb.lb[0].id
  name            = format("BackEndAddressPool-%d", var.lb_target_ports[count.index])
}

resource "azurerm_lb_probe" "lb_probe" {
  count           = var.deploy_lb ? length(var.lb_target_ports) : 0
  loadbalancer_id = azurerm_lb.lb[0].id
  name            = format("probe-%d", var.lb_target_ports[count.index])
  port            = var.lb_health_check_port
  protocol        = "Tcp"
}

resource "azurerm_lb_rule" "lb_rule" {
  count                          = var.deploy_lb ? length(var.lb_target_ports) : 0
  loadbalancer_id                = azurerm_lb.lb[0].id
  name                           = format("LBRule-%d", var.lb_target_ports[count.index])
  protocol                       = "Tcp"
  frontend_port                  = var.lb_target_ports[count.index]
  backend_port                   = var.lb_target_ports[count.index]
  frontend_ip_configuration_name = "PublicIPAddress"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.lb_backend_pool[count.index].id]
  probe_id                       = azurerm_lb_probe.lb_probe[count.index].id
}

resource "azurerm_network_interface_backend_address_pool_association" "lb_association" {
  count                   = var.deploy_lb ? var.node_count * length(var.lb_target_ports) : 0
  network_interface_id    = azurerm_network_interface.outside[floor(count.index / length(var.lb_target_ports))].id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.lb_backend_pool[count.index % length(var.lb_target_ports)].id
}