/*
Creates a VNet with three subnets
Creates three NSGs and assign to the three subnets. The NSGs are "allow-all"
Creates a Palo Alto Firewall and attaches it to the three subnets
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
variable "az-region" {
  default = "eastus2"
}

### VNet Variables ###
variable "az-vnet-rg" {
  default = "aan-terraform-vnet-rg"
}

variable "az-vnet" {
  default = "aan-tf-1-vnet"
}

variable "az-untrust-nsg" {
  default = "aan-tf-untrust-nsg"
}

variable "az-trust-nsg" {
  default = "aan-tf-trust-nsg"
}

variable "az-mgnt-nsg" {
  default = "aan-tf-mgnt-nsg"
}

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

##### Firewal Variables #####
# Firwall resource group
variable "az-fw-rg" {
  default = "aan-terraform-fw-rg"
}

#Firewall availability set
variable "az-fw-as" {
  default = "aan-fw-as"
}

# Management pulic IP
variable "az-mgnt-pip" {
  default = "aan-fw-mgnt-pip"
}

# Untrust public IP
variable "az-untrust-pip" {
  default = "aan-fw-untrust-pip"
}

variable "az-fw1-nic0" {
  default = "aan-tf-fw1-nic0"
}

variable "az-fw1-nic1" {
  default = "aan-tf-fw1-nic1"
}

variable "az-fw1-nic2" {
  default = "aan-tf-fw1-nic2"
}

# No "-" in PAN name
variable "az-pan-fw1-name" {
  default = "aantfegfw1"
}

variable "az-disk-name" {
  default = "egfw1-disk"
}

variable "az-fw-size" {
  default = "Standard_D3_v2"
}

# To use a pay as you go license set name to "bundle1" or "bundle2"
# To use a purchased license change name to "byol"
variable "az-fw-sku" {
  default = "bundle1"
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

##############################################################
# Create PAN Firewalls VM & Required Resources

# Create FW Resource Group
resource "azurerm_resource_group" "fw1-rg" {
  name     = var.az-fw-rg
  location = var.az-region
}

# Create Availability Set to place both firewalls in.
# If using availability-sets both VMs have to be in the same resource group
resource "azurerm_availability_set" "firewall-as1" {
  name                         = var.az-fw-as
  location                     = azurerm_resource_group.fw1-rg.location
  resource_group_name          = azurerm_resource_group.fw1-rg.name
  platform_fault_domain_count  = 2
  platform_update_domain_count = 2
  managed                      = true
}

# Create three NICs with IPs for firewall VM
resource "azurerm_public_ip" "fw1-mgnt-pip" {
  name                = var.az-mgnt-pip
  location            = azurerm_resource_group.fw1-rg.location
  resource_group_name = azurerm_resource_group.fw1-rg.name
  allocation_method   = "Static"
  sku                 = "Standard"   
}

resource "azurerm_public_ip" "fw1-untrust-pip" {
  name                = var.az-untrust-pip
  location            = azurerm_resource_group.fw1-rg.location
  resource_group_name = azurerm_resource_group.fw1-rg.name
  allocation_method   = "Static"
  sku                 = "Standard"  
}

resource "azurerm_network_interface" "fw1-nic0" {
  name                   = var.az-fw1-nic0
  location               = azurerm_resource_group.fw1-rg.location
  resource_group_name    = azurerm_resource_group.fw1-rg.name
  depends_on             = [azurerm_virtual_network.main-vnet]

  ip_configuration {
    name                          = "mgnt-ip"
    subnet_id                     = azurerm_subnet.mgnt-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.fw1-mgnt-pip.id
  }
}

resource "azurerm_network_interface" "fw1-nic1" {
  name                   = var.az-fw1-nic1
  location               = azurerm_resource_group.fw1-rg.location
  resource_group_name    = azurerm_resource_group.fw1-rg.name
  depends_on             = [azurerm_virtual_network.main-vnet]
  enable_ip_forwarding   = true
  enable_accelerated_networking = true

  ip_configuration {
    name                          = "untrust-ip"
    subnet_id                     = azurerm_subnet.untrust-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.fw1-untrust-pip.id
  }
}

resource "azurerm_network_interface" "fw1-nic2" {
  name                   = var.az-fw1-nic2
  location               = azurerm_resource_group.fw1-rg.location
  resource_group_name    = azurerm_resource_group.fw1-rg.name
  depends_on             = [azurerm_virtual_network.main-vnet]
  enable_ip_forwarding = true
  enable_accelerated_networking = true

  ip_configuration {
    name                          = "trust-ip"
    subnet_id                     = azurerm_subnet.trust-subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

### Create VMs ###
/*
Using the AzCLI, accept Marketplace the offer terms prior to deployment. 
This only need to be done once per subscription
```
az vm image terms accept --urn paloaltonetworks:vmseries1:bundle2:latest
```
To see options other Markerplace offerings:
az vm image list --all --publisher paloaltonetworks --offer vmseries --output table
```
If using availability-sets both VMs have to be in the same resource group
*/
resource "azurerm_virtual_machine" "pan-fw1" {
  name                         = var.az-pan-fw1-name
  location                     = azurerm_resource_group.fw1-rg.location
  resource_group_name          = azurerm_resource_group.fw1-rg.name
  availability_set_id          = azurerm_availability_set.firewall-as1.id
  vm_size                      = var.az-fw-size
  primary_network_interface_id = azurerm_network_interface.fw1-nic0.id
  network_interface_ids        = [azurerm_network_interface.fw1-nic0.id, 
                                  azurerm_network_interface.fw1-nic1.id, 
                                  azurerm_network_interface.fw1-nic2.id]
  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  # To use a pay as you go license set name to "bundle1" or "bundle2"
  # To use a purchased license change name to "byol"
  plan {
    name      = var.az-fw-sku
    publisher = "paloaltonetworks"
    product   = "vmseries-flex"
  }

  # to use a pay as you go license set sku to "bundle1" or "bundle2"
  # To use a purchased license change sku to "byol"
  storage_image_reference {
    publisher = "paloaltonetworks"
    offer     = "vmseries-flex"
    sku       = var.az-fw-sku
    version   = "latest"
  }

  storage_os_disk {
    name              = var.az-disk-name
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = var.az-pan-fw1-name
    # Note: admin_username cannot be "admin"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}
