# Create a VNet with three subnets
# Create three NSGs and assign to the three subnet

# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "=2.46.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Create Resource Group
resource "azurerm_resource_group" "aan-tf-1-rg" {
  name     = "aan-tf-1-rg"
  location = "eastus2"
}

# Create a virtual network within the resource group
resource "azurerm_virtual_network" "aan-tf-1-vnet" {
  name                = "aan-tf-1-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.aan-tf-1-rg.location
  resource_group_name = azurerm_resource_group.aan-tf-1-rg.name
}

#Create Subnets
resource "azurerm_subnet" "aan-tf-untrust-subnet" {
  name                 = "aan-tf-untrust-subnet"
  resource_group_name  = azurerm_resource_group.aan-tf-1-rg.name
  virtual_network_name = azurerm_virtual_network.aan-tf-1-vnet.name
  address_prefixes     = ["10.0.0.0/24"]
}
resource "azurerm_subnet" "aan-tf-trust-subnet" {
  name                 = "aan-tf-trust-subnet"
  resource_group_name  = azurerm_resource_group.aan-tf-1-rg.name
  virtual_network_name = azurerm_virtual_network.aan-tf-1-vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}
resource "azurerm_subnet" "aan-tf-mgnt-subnet" {
  name                 = "aan-tf-mgnt-subnet"
  resource_group_name  = azurerm_resource_group.aan-tf-1-rg.name
  virtual_network_name = azurerm_virtual_network.aan-tf-1-vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Create Network Security Groups
resource "azurerm_network_security_group" "aan-tf-untrust-nsg" {
  name                = "aan-tf-untrust-nsg"
  location            = azurerm_resource_group.aan-tf-1-rg.location
  resource_group_name = azurerm_resource_group.aan-tf-1-rg.name
  security_rule {
    name                       = "allow-all"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}
resource "azurerm_network_security_group" "aan-tf-trust-nsg" {
  name                = "aan-tf-trust-nsg"
  location            = "eastus2"
  resource_group_name = "aan-tf-1-rg"
  security_rule {
    name                       = "allow-all"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}
resource "azurerm_network_security_group" "aan-tf-mgnt-nsg" {
  name                = "aan-tf-mgnt-nsg"
  location            = "eastus2"
  resource_group_name = "aan-tf-1-rg"
  security_rule {
    name                       = "allow-all"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Create NSG to subnet associations
resource "azurerm_subnet_network_security_group_association" "untrust-nsg-assoc" {
  subnet_id                 = azurerm_subnet.aan-tf-untrust-subnet.id
  network_security_group_id = azurerm_network_security_group.aan-tf-untrust-nsg.id
}
resource "azurerm_subnet_network_security_group_association" "trust-nsg-assoc" {
  subnet_id                 = azurerm_subnet.aan-tf-trust-subnet.id
  network_security_group_id = azurerm_network_security_group.aan-tf-trust-nsg.id
}
resource "azurerm_subnet_network_security_group_association" "mgnt-nsg-assoc" {
  subnet_id                 = azurerm_subnet.aan-tf-mgnt-subnet.id
  network_security_group_id = azurerm_network_security_group.aan-tf-mgnt-nsg.id
}

