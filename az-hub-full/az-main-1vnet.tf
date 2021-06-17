/*
Creates a VNet with three subnets
Creates three NSGs and assign to the three subnets. The NSGs are "allow-all"
Creates a Palo Alto Firewall and attaches it to the three subnets
*/

terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      #version = "=2.46.0"
      version = "=2.60.0"
    }
  }
}

provider "azurerm" {
  features {}
}

###### Variables Start #######
variable "az-region" {
  default = "eastus2"
}

### VNet Variables ###
variable "az-vnet-rg" {
  default = "aan-terraform-hub-rg"
}

variable "az-vnet" {
  default = "aan-tf-hub-vnet"
}

variable "vnet-adx" {
  default = ["10.100.0.0/16"]
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

