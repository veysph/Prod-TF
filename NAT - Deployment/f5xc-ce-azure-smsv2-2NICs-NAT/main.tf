resource "random_id" "suffix" {
  byte_length = 2
}

data "azurerm_resource_group" "rg" {
  name = var.ressource_group
}

data "azurerm_subnet" "outside" {
  name                 = var.outside-subnet-name
  virtual_network_name = var.vnet
  resource_group_name  = data.azurerm_resource_group.rg.name
}

data "azurerm_subnet" "inside" {
  name                 = var.inside-subnet-name
  virtual_network_name = var.vnet
  resource_group_name  = data.azurerm_resource_group.rg.name
}

#
# Create Network Security Group and rule
#
resource "azurerm_network_security_group" "f5xc-ce-outside-nsg" {
  name                = format("%s-%s-%s", var.f5xc-ce-site-name, random_id.suffix.hex,"nsg-SLO")
  location            = var.location
  resource_group_name = data.azurerm_resource_group.rg.name

  #
  #Please uncomment / adapt the two rules bellow to allow ICMP and/or SSH access to the public IP of SLO interface
  #
  # security_rule {
  #   name                       = "ICMP-from-trusted"
  #   priority                   = 100
  #   direction                  = "Inbound"
  #   access                     = "Allow"
  #   protocol                   = "Icmp"
  #   source_port_range          = "*"
  #   destination_port_range     = "*"
  #   source_address_prefix      = "XX.XX.XX.XX/XX"
  #   destination_address_prefix = "*"
  # }

  # security_rule {
  #   name                       = "SSH-from-trusted"
  #   priority                   = 110
  #   direction                  = "Inbound"
  #   access                     = "Allow"
  #   protocol                   = "Tcp"
  #   source_port_range          = "*"
  #   destination_port_range     = "22"
  #   source_address_prefix      = "XX.XX.XX.XX/XX"
  #   destination_address_prefix = "*"
  # }
}

resource "azurerm_network_interface" "outside_nic" {
  name                          = format("%s-%s-%s", var.f5xc-ce-site-name, random_id.suffix.hex, "outside-nic")
  location                      = var.location
  resource_group_name           = data.azurerm_resource_group.rg.name
  enable_ip_forwarding = true

  ip_configuration {
    name                          = format("%s-%s-%s", var.f5xc-ce-site-name, random_id.suffix.hex, "outside-ip")
    subnet_id                     = data.azurerm_subnet.outside.id
    # private_ip_address_allocation = "Dynamic"
    private_ip_address_allocation = "Static"
    private_ip_address            = var.slo-private-ip
  }

  tags = {
    Name   = format("%s-%s-%s", var.f5xc-ce-site-name, random_id.suffix.hex, "outside-nic")
    source = "terraform"
    owner = var.owner
  }
}

resource "azurerm_network_interface_security_group_association" "outside-nic-nsg-attachment" {
  network_interface_id      = azurerm_network_interface.outside_nic.id
  network_security_group_id = azurerm_network_security_group.f5xc-ce-outside-nsg.id
}

resource "azurerm_network_interface" "inside_nic" {
  name                = format("%s-%s-%s", var.f5xc-ce-site-name, random_id.suffix.hex, "inside-nic")
  location            = var.location
  resource_group_name = data.azurerm_resource_group.rg.name
  enable_ip_forwarding = true

  ip_configuration {
    name                          = format("%s-%s-%s", var.f5xc-ce-site-name, random_id.suffix.hex, "inside-ip")
    subnet_id                     = data.azurerm_subnet.inside.id
    # private_ip_address_allocation = "Dynamic"
    private_ip_address_allocation = "Static"
    private_ip_address            = var.sli-private-ip
  }

  tags = {
    Name   = format("%s-%s-%s", var.f5xc-ce-site-name, random_id.suffix.hex, "inside-nic")
    source = "terraform"
    owner = var.owner
  }
}

resource "azurerm_linux_virtual_machine" "f5xc-ce-nodes" {
  resource_group_name   = data.azurerm_resource_group.rg.name
  name                  = format("%s-%s", var.f5xc-ce-site-name, random_id.suffix.hex)
  location              = var.location
  size                  = var.f5xc_sms_instance_type
  network_interface_ids = [azurerm_network_interface.outside_nic[count.index].id, azurerm_network_interface.inside_nic.id]

  admin_username = "cloud-user"

  boot_diagnostics {

  }

  admin_ssh_key {
    username   = var.ssh_username
    public_key = var.ssh_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  plan {
    name      = "f5xccebyol"
    publisher = "f5-networks"
    product   = "f5xc_customer_edge"
  }

  source_image_reference {
    publisher = "f5-networks"
    offer     = "f5xc_customer_edge"
    sku       = "f5xccebyol"
    version   = "2024.44.1"
  }

  custom_data = base64encode(data.cloudinit_config.f5xc-ce_config.rendered)
  depends_on  = [data.azurerm_resource_group.rg]

  tags = {
    Name   = format("%s-%s", var.f5xc-ce-site-name, random_id.suffix.hex)
    source = "terraform"
    owner  = var.owner
  }
}