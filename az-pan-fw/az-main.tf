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

# Create Resource Group
resource "azurerm_resource_group" "vnet-rg" {
  name     = "aan-terraform-vnet1-rg"
  location = "eastus2"
}

# Create a virtual network within the resource group
resource "azurerm_virtual_network" "main-vnet" {
  name                = "aan-tf-1-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.vnet-rg.location
  resource_group_name = azurerm_resource_group.vnet-rg.name
}

#Create Subnets
resource "azurerm_subnet" "untrust-subnet" {
  name                 = "aan-tf-untrust-subnet"
  resource_group_name  = azurerm_resource_group.vnet-rg.name
  virtual_network_name = azurerm_virtual_network.main-vnet.name
  address_prefixes     = ["10.0.0.0/24"]
}
resource "azurerm_subnet" "trust-subnet" {
  name                 = "aan-tf-trust-subnet"
  resource_group_name  = azurerm_resource_group.vnet-rg.name
  virtual_network_name = azurerm_virtual_network.main-vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}
resource "azurerm_subnet" "mgnt-subnet" {
  name                 = "aan-tf-mgnt-subnet"
  resource_group_name  = azurerm_resource_group.vnet-rg.name
  virtual_network_name = azurerm_virtual_network.main-vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Create Network Security Groups
resource "azurerm_network_security_group" "untrust-nsg" {
  name                = "aan-tf-untrust-nsg"
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
  name                = "aan-tf-trust-nsg"
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
  name                = "aan-tf-mgnt-nsg"
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
  name     = "aan-terraform-fw1-rg"
  location = azurerm_resource_group.vnet-rg.location
}

# Create Availability Set to place both firewalls in.
# If using availability-sets both VMs have to be in the same resource group
resource "azurerm_availability_set" "firewall-as1" {
  name                         = "aan-firewall-as1"
  location                     = azurerm_resource_group.fw1-rg.location
  resource_group_name          = azurerm_resource_group.fw1-rg.name
  platform_fault_domain_count  = 2
  platform_update_domain_count = 2
  managed                      = true
}

# Create three NICs with IPs for firewall VM
resource "azurerm_public_ip" "fw1-mgnt-pip" {
  name                = "aan-egfw-1-mgnt-pip"
  location               = azurerm_resource_group.fw1-rg.location
  resource_group_name    = azurerm_resource_group.fw1-rg.name
  allocation_method   = "Static"
}

resource "azurerm_public_ip" "fw1-untrust-pip" {
  name                = "aan-egfw-1-untrust-pip"
  location               = azurerm_resource_group.fw1-rg.location
  resource_group_name    = azurerm_resource_group.fw1-rg.name
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "fw1-nic0" {
  name                   = "aan-tf-fw1-nic0"
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
  name                   = "aan-tf-fw1-nic1"
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
  name                   = "aan-tf-fw1-nic2"
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
  name                         = "aantfegfw1"
  location                     = azurerm_resource_group.fw1-rg.location
  resource_group_name          = azurerm_resource_group.fw1-rg.name
  availability_set_id          = azurerm_availability_set.firewall-as1.id
  # Enter VM Size below
  vm_size                      = "Standard_D3_v2"
  primary_network_interface_id = azurerm_network_interface.fw1-nic0.id
  network_interface_ids        = [azurerm_network_interface.fw1-nic0.id, 
                                  azurerm_network_interface.fw1-nic1.id, 
                                  azurerm_network_interface.fw1-nic2.id]
  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  # To use a pay as you go license set name to "bundle1" or "bundle2"
  # To use a purchased license change name to "byol"
  plan {
    name = "bundle1"
    publisher = "paloaltonetworks"
    product = "vmseries-flex"
  }

  # to use a pay as you go license set sku to "bundle1" or "bundle2"
  # To use a purchased license change sku to "byol"
  storage_image_reference {
    publisher = "paloaltonetworks"
    offer     = "vmseries-flex"
    sku       = "bundle1"
    version   = "latest"
  }

  storage_os_disk {
    name              = "egfw1-disk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "aantfegfw1"
    # Note: admin_username cannot be "admin"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}
