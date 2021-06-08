/*
Creates a resource group
Creates a VNet with three subnets in the resource group
Creates three NSGs and assign to the three subnets. The NSGs are "allow-all"
*/

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

###### Variables Start #######
# Set Azure Region
variable "az-region" {
  default = "eastus2"
}

### VNet Variables ###
# Vnet Resource Group 
variable "az-vnet-rg" {
  default = "aan-terraform-vnet2-rg"
}

# VNet Name
variable "az-vnet" {
  default = "aan-tf-vnet2"
}

# NSG NAmes
variable "az-untrust-nsg" {
  default = "aan-tf-untrust-nsg"
}
variable "az-trust-nsg" {
  default = "aan-tf-trust-nsg"
}
variable "az-mgnt-nsg" {
  default = "aan-tf-mgnt-nsg"
}

# VNet Subnet Addresses
variable "vnet-adx" {
  default = ["10.0.0.0/16"]
}
variable "untrust-adx" {
  default = ["10.0.0.0/24"]
}
variable "trust-adx" {
  default = ["10.0.1.0/24"]
}
variable "mgnt-adx" {
  default = ["10.0.2.0/24"]
}

###### End of Variables #######

# Create Resource Group
resource "azurerm_resource_group" "vnet-rg" {
  name     = var.az-vnet-rg
  location = var.az-region
}

# Create a virtual network within the resource group
resource "azurerm_virtual_network" "main-vnet" {
  name                = var.az-vnet
  address_space       = var.vnet-adx
  location            = azurerm_resource_group.vnet-rg.location
  resource_group_name = azurerm_resource_group.vnet-rg.name
}

#Create Subnets
resource "azurerm_subnet" "untrust-subnet" {
  name                 = "untrust-subnet"
  resource_group_name  = azurerm_resource_group.vnet-rg.name
  virtual_network_name = azurerm_virtual_network.main-vnet.name
  address_prefixes     = var.untrust-adx
}
resource "azurerm_subnet" "trust-subnet" {
  name                 = "trust-subnet"
  resource_group_name  = azurerm_resource_group.vnet-rg.name
  virtual_network_name = azurerm_virtual_network.main-vnet.name
  address_prefixes     = var.trust-adx
}
resource "azurerm_subnet" "mgnt-subnet" {
  name                 = "mgnt-subnet"
  resource_group_name  = azurerm_resource_group.vnet-rg.name
  virtual_network_name = azurerm_virtual_network.main-vnet.name
  address_prefixes     = var.mgnt-adx
}

# Create Network Security Groups
resource "azurerm_network_security_group" "untrust-nsg" {
  name                = var.az-untrust-nsg
  location            = azurerm_resource_group.vnet-rg.location
  resource_group_name = azurerm_resource_group.vnet-rg.name
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
resource "azurerm_network_security_group" "trust-nsg" {
  name                = var.az-trust-nsg
  location            = azurerm_resource_group.vnet-rg.location
  resource_group_name = azurerm_resource_group.vnet-rg.name
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
resource "azurerm_network_security_group" "mgnt-nsg" {
  name                = var.az-mgnt-nsg
  location            = azurerm_resource_group.vnet-rg.location
  resource_group_name = azurerm_resource_group.vnet-rg.name
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
  subnet_id                 = azurerm_subnet.untrust-subnet.id
  network_security_group_id = azurerm_network_security_group.untrust-nsg.id
}
resource "azurerm_subnet_network_security_group_association" "trust-nsg-assoc" {
  subnet_id                 = azurerm_subnet.trust-subnet.id
  network_security_group_id = azurerm_network_security_group.trust-nsg.id
}
resource "azurerm_subnet_network_security_group_association" "mgnt-nsg-assoc" {
  subnet_id                 = azurerm_subnet.mgnt-subnet.id
  network_security_group_id = azurerm_network_security_group.mgnt-nsg.id
}
