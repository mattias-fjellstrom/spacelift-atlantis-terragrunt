locals {
  cidr = "10.0.0.0/16"
}

resource "azurerm_virtual_network" "default" {
  name = "vnet-atlantis"

  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name

  address_space = [
    local.cidr,
  ]
}

resource "azurerm_subnet" "atlantis" {
  name                 = "snet-atlantis"
  virtual_network_name = azurerm_virtual_network.default.name
  resource_group_name  = azurerm_resource_group.default.name

  address_prefixes = [
    cidrsubnet(local.cidr, 8, 0),
  ]
}

resource "azurerm_network_security_group" "vmss" {
  name                = "nsg-vmss-atlantis"
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name

  security_rule {
    name                       = "allow-http"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "4141"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-ssh"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "vmss" {
  subnet_id                 = azurerm_subnet.atlantis.id
  network_security_group_id = azurerm_network_security_group.vmss.id
}
