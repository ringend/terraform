/*
Create ExpressRoute Gateway
Create Public IP and Subnet for ExpressRoute Gateway
*/

# Varibles for ExpressRoute Gateway
variable "az-ergw" {
  type = map
  default = {
    "name"          = "aan-tf-ergw"
    "pip"           = "aan-ergw-pip"
    "subnet-prefix" = "[10.100.100.0/24]"
  }
}
variable "ergw-subnet-adx" {
  default = ["10.100.100.0/24"]
}



resource "azurerm_public_ip" "ergw-pip" {
  name                = var.az-ergw["pip"]
  location            = azurerm_resource_group.vnet-rg.location
  resource_group_name = azurerm_resource_group.vnet-rg.name
  allocation_method   = "Dynamic"
}

resource "azurerm_subnet" "ergw-subnet" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.vnet-rg.name
  virtual_network_name = azurerm_virtual_network.main-vnet.name
  address_prefixes     = var.ergw-subnet-adx
}

resource "azurerm_virtual_network_gateway" "ergw" {
  name                = var.az-ergw["name"]
  location            = azurerm_resource_group.vnet-rg.location
  resource_group_name = azurerm_resource_group.vnet-rg.name

  type     = "ExpressRoute"
  vpn_type = "RouteBased"
  sku      = "Standard"
#  sku      = "ErGw1AZ"

  ip_configuration {
    public_ip_address_id          =  azurerm_public_ip.ergw-pip.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     =  azurerm_subnet.ergw-subnet.id  
  }
}
