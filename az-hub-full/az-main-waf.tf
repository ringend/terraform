/*
F5 BIG-IP Web Application Firewall and required resources.
Creates three NSGs and three subnets.
Assign the three NSGs assign to the three subnets. 
Creates two F5 BIG-IP Web Application Firewalls and attaches it to the three subnets
```
Using the AzCLI, accept Marketplace the offer terms prior to deployment. 
This only need to be done once per subscription
```
 az vm image terms accept --urn f5-networks:f5-big-ip-good:f5-bigip-virtual-edition-200m-good-hourly:latest
or 
 az vm image terms accept --urn f5-networks:f5-big-ip-byol:f5-big-all-1slot-byol:latest

```
To see options other Markerplace offerings:

az vm image list --all --publisher f5-networks --offer f5-big-ip-good --output table
```
If using availability-sets both VMs have to be in the same resource group
*/

######## Variables Start #########

variable "az-waf-external-nsg" {
  default = "aan-tf-waf-external-nsg"
}

variable "az-waf-trust-nsg" {
  default = "aan-tf-waf-trust-nsg"
}

variable "az-waf-mgnt-nsg" {
  default = "aan-tf-waf-mgnt-nsg"
}

variable "waf-external-adx" {
  default = ["10.100.20.0/24"]
}

variable "waf-trust-adx" {
  default = ["10.100.21.0/24"]
}

variable "waf-mgnt-adx" {
  default = ["10.100.22.0/24"]
}

##### Firewal Variables #####
# Firwall resource group
variable "az-waf-rg" {
  default = "aan-terraform-waf-rg"
}

#Firewall availability set
variable "az-waf-as" {
  default = "aan-waf-as"
}

# Management pulic IP for both VMs
variable "az-waf1-mgnt-pip" {
  default = "aan-tf-waf1-mgnt-pip"
}
variable "az-waf2-mgnt-pip" {
  default = "aan-tf-waf2-mgnt-pip"
}

# nic0 for both VMs
variable "az-waf1-nic0" {
  default = "aan-tf-waf1-nic0"
}
variable "az-waf2-nic0" {
  default = "aan-tf-waf2-nic0"
}

# nic1 for both VMs
variable "az-waf1-nic1" {
  default = "aan-tf-waf1-nic1"
}
variable "az-waf2-nic1" {
  default = "aan-tf-waf2-nic1"
}

# nic2 for both VMs
variable "az-waf1-nic2" {
  default = "aan-tf-waf1-nic2"
}
variable "az-waf2-nic2" {
  default = "aan-tf-waf2-nic2"
}

# Name for both VMs
# No "-" in f5 name
variable "az-f5-waf1-name" {
  default = "aantfwaf1"
}
variable "az-f5-waf2-name" {
  default = "aantfwaf2"
}

# Disk name for both VMs
variable "az-waf1-disk-name" {
  default = "aan-waf1-disk"
}
variable "az-waf2-disk-name" {
  default = "aan-waf2-disk"
}

variable "az-waf-size" {
  default = "Standard_DS4_v2"
}

# Change SKU based on which license is selected. 
variable "az-waf-sku" {
  default = "f5-big-all-1slot-byol"
  #default = "f5-bigip-virtual-edition-200m-good-hourly"
  #default = "f5-bigip-virtual-edition-1g-good-hourly"
}

###### End of Variables #######

#Create Subnets
resource "azurerm_subnet" "waf-external-subnet" {
  name                 = "waf-external-subnet"
  resource_group_name  = azurerm_resource_group.vnet-rg.name
  virtual_network_name = azurerm_virtual_network.main-vnet.name
  address_prefixes     = var.waf-external-adx
}
resource "azurerm_subnet" "waf-trust-subnet" {
  name                 = "waf-trust-subnet"
  resource_group_name  = azurerm_resource_group.vnet-rg.name
  virtual_network_name = azurerm_virtual_network.main-vnet.name
  address_prefixes     = var.waf-trust-adx
}
resource "azurerm_subnet" "waf-mgnt-subnet" {
  name                 = "waf-mgnt-subnet"
  resource_group_name  = azurerm_resource_group.vnet-rg.name
  virtual_network_name = azurerm_virtual_network.main-vnet.name
  address_prefixes     = var.waf-mgnt-adx
}


# Create Network Security Groups
resource "azurerm_network_security_group" "waf-external-nsg" {
  name                = var.az-waf-external-nsg
  location            = azurerm_resource_group.vnet-rg.location
  resource_group_name = azurerm_resource_group.waf-rg.name
  security_rule {
    name                       = "allow-all"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}
resource "azurerm_network_security_group" "waf-trust-nsg" {
  name                = var.az-waf-trust-nsg
  location            = azurerm_resource_group.vnet-rg.location
  resource_group_name = azurerm_resource_group.waf-rg.name
  security_rule {
    name                       = "icmp-in"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "ICMP"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "10.0.0.0/8"
    destination_address_prefix = "*"
  }
}
resource "azurerm_network_security_group" "waf-mgnt-nsg" {
  name                = var.az-waf-mgnt-nsg
  location            = azurerm_resource_group.vnet-rg.location
  resource_group_name = azurerm_resource_group.waf-rg.name
  security_rule {
    name                       = "Deny-all"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Create NSG to subnet associations
resource "azurerm_subnet_network_security_group_association" "waf-external-nsg-assoc" {
  subnet_id                 = azurerm_subnet.waf-external-subnet.id
  network_security_group_id = azurerm_network_security_group.waf-external-nsg.id
}
resource "azurerm_subnet_network_security_group_association" "waf-trust-nsg-assoc" {
  subnet_id                 = azurerm_subnet.waf-trust-subnet.id
  network_security_group_id = azurerm_network_security_group.waf-trust-nsg.id
}
resource "azurerm_subnet_network_security_group_association" "waf-mgnt-nsg-assoc" {
  subnet_id                 = azurerm_subnet.waf-mgnt-subnet.id
  network_security_group_id = azurerm_network_security_group.waf-mgnt-nsg.id
}


##############################################################
# Create f5 Firewalls VM & Required Resources

# Create waf Resource Group
resource "azurerm_resource_group" "waf-rg" {
  name     = var.az-waf-rg
  location = var.az-region
}

# Create Availability Set to place both firewalls in.
# If using availability-sets both VMs have to be in the same resource group
resource "azurerm_availability_set" "waf-as" {
  name                         = var.az-waf-as
  location                     = azurerm_resource_group.waf-rg.location
  resource_group_name          = azurerm_resource_group.waf-rg.name
  platform_fault_domain_count  = 2
  platform_update_domain_count = 2
  managed                      = true
}


##### Create First VM #####
# Create three NICs with IPs for firewall VM
resource "azurerm_public_ip" "waf1-mgnt-pip" {
  name                = var.az-waf1-mgnt-pip
  location            = azurerm_resource_group.waf-rg.location
  resource_group_name = azurerm_resource_group.waf-rg.name
  allocation_method   = "Static"
  sku                 = "Standard"   
}

resource "azurerm_network_interface" "waf1-nic0" {
  name                   = var.az-waf1-nic0
  location               = azurerm_resource_group.waf-rg.location
  resource_group_name    = azurerm_resource_group.waf-rg.name
  depends_on             = [azurerm_virtual_network.main-vnet]

  ip_configuration {
    name                          = "mgnt-ip"
    subnet_id                     = azurerm_subnet.waf-mgnt-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.waf1-mgnt-pip.id
  }
}

resource "azurerm_network_interface" "waf1-nic1" {
  name                   = var.az-waf1-nic1
  location               = azurerm_resource_group.waf-rg.location
  resource_group_name    = azurerm_resource_group.waf-rg.name
  depends_on             = [azurerm_virtual_network.main-vnet]
  enable_ip_forwarding   = true
  enable_accelerated_networking = true

  ip_configuration {
    name                          = "external-ip"
    subnet_id                     = azurerm_subnet.waf-external-subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface" "waf1-nic2" {
  name                   = var.az-waf1-nic2
  location               = azurerm_resource_group.waf-rg.location
  resource_group_name    = azurerm_resource_group.waf-rg.name
  depends_on             = [azurerm_virtual_network.main-vnet]
  enable_ip_forwarding = true
  enable_accelerated_networking = true

  ip_configuration {
    name                          = "trust-ip"
    subnet_id                     = azurerm_subnet.waf-trust-subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_machine" "f5-waf1" {
  name                         = var.az-f5-waf1-name
  location                     = azurerm_resource_group.waf-rg.location
  resource_group_name          = azurerm_resource_group.waf-rg.name
  availability_set_id          = azurerm_availability_set.waf-as.id
  vm_size                      = var.az-waf-size
  primary_network_interface_id = azurerm_network_interface.waf1-nic0.id
  network_interface_ids        = [azurerm_network_interface.waf1-nic0.id, 
                                  azurerm_network_interface.waf1-nic1.id, 
                                  azurerm_network_interface.waf1-nic2.id]
  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  # To use a pay as you go license set name to "bundle1" or "bundle2"
  # To use a purchased license change name to "byol"
  plan {
    name      = var.az-waf-sku
    publisher = "f5-networks"
    product   = "f5-big-ip-byol"
  }

  # to use a pay as you go license set sku to "bundle1" or "bundle2"
  # To use a purchased license change sku to "byol"
  storage_image_reference {
    publisher = "f5-networks"
    offer     = "f5-big-ip-byol"
    sku       = var.az-waf-sku
    version   = "latest"
  }

  storage_os_disk {
    name              = var.az-waf1-disk-name
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  os_profile {
    computer_name  = var.az-f5-waf1-name
    # Note: admin_username cannot be "admin"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}


#### Create Second VM #####
# Create three NICs with IPs for firewall VM
resource "azurerm_public_ip" "waf2-mgnt-pip" {
  name                = var.az-waf2-mgnt-pip
  location            = azurerm_resource_group.waf-rg.location
  resource_group_name = azurerm_resource_group.waf-rg.name
  allocation_method   = "Static"
  sku                 = "Standard"   
}

resource "azurerm_network_interface" "waf2-nic0" {
  name                   = var.az-waf2-nic0
  location               = azurerm_resource_group.waf-rg.location
  resource_group_name    = azurerm_resource_group.waf-rg.name
  depends_on             = [azurerm_virtual_network.main-vnet]

  ip_configuration {
    name                          = "mgnt-ip"
    subnet_id                     = azurerm_subnet.waf-mgnt-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.waf2-mgnt-pip.id
  }
}

resource "azurerm_network_interface" "waf2-nic1" {
  name                   = var.az-waf2-nic1
  location               = azurerm_resource_group.waf-rg.location
  resource_group_name    = azurerm_resource_group.waf-rg.name
  depends_on             = [azurerm_virtual_network.main-vnet]
  enable_ip_forwarding   = true
  enable_accelerated_networking = true

  ip_configuration {
    name                          = "external-ip"
    subnet_id                     = azurerm_subnet.waf-external-subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface" "waf2-nic2" {
  name                   = var.az-waf2-nic2
  location               = azurerm_resource_group.waf-rg.location
  resource_group_name    = azurerm_resource_group.waf-rg.name
  depends_on             = [azurerm_virtual_network.main-vnet]
  enable_ip_forwarding = true
  enable_accelerated_networking = true

  ip_configuration {
    name                          = "trust-ip"
    subnet_id                     = azurerm_subnet.waf-trust-subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_machine" "f5-waf2" {
  name                         = var.az-f5-waf2-name
  location                     = azurerm_resource_group.waf-rg.location
  resource_group_name          = azurerm_resource_group.waf-rg.name
  availability_set_id          = azurerm_availability_set.waf-as.id
  vm_size                      = var.az-waf-size
  primary_network_interface_id = azurerm_network_interface.waf2-nic0.id
  network_interface_ids        = [azurerm_network_interface.waf2-nic0.id, 
                                  azurerm_network_interface.waf2-nic1.id, 
                                  azurerm_network_interface.waf2-nic2.id]
  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  # To use a pay as you go license set name to "bundle1" or "bundle2"
  # To use a purchased license change name to "byol"
  plan {
    name      = var.az-waf-sku
    publisher = "f5-networks"
    product   = "f5-big-ip-byol"
  }

  # to use a pay as you go license set sku to "bundle1" or "bundle2"
  # To use a purchased license change sku to "byol"
  storage_image_reference {
    publisher = "f5-networks"
    offer     = "f5-big-ip-byol"
    sku       = var.az-waf-sku
    version   = "latest"
  }

  storage_os_disk {
    name              = var.az-waf2-disk-name
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  os_profile {
    computer_name  = var.az-f5-waf2-name
    # Note: admin_username cannot be "admin"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}
