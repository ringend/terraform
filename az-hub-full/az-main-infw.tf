/*
Palo Alto Ingress Firewall and required resources.
Creates three NSGs and three subnets.
Assign the three NSGs assign to the three subnets. 
Creates two Palo Alto Firewalls and attaches it to the three subnets
```
Using the AzCLI, accept Marketplace the offer terms prior to deployment. 
This only need to be done once per subscription
```
az vm image terms accept --urn paloaltonetworks:vmseries1:bundle2:latest
or
az vm image terms accept --urn paloaltonetworks:vmseries1:byol:latest
```
To see options other Markerplace offerings:
az vm image list --all --publisher paloaltonetworks --offer vmseries --output table
```
If using availability-sets both VMs have to be in the same resource group
*/

######## Variables Start #########

variable "az-ifw-untrust-nsg" {
  default = "aan-tf-ifw-untrust-nsg"
}

variable "az-ifw-trust-nsg" {
  default = "aan-tf-ifw-trust-nsg"
}

variable "az-ifw-mgnt-nsg" {
  default = "aan-tf-ifw-mgnt-nsg"
}

variable "ifw-untrust-adx" {
  default = ["10.100.10.0/24"]
}

variable "ifw-trust-adx" {
  default = ["10.100.11.0/24"]
}

variable "ifw-mgnt-adx" {
  default = ["10.100.12.0/24"]
}

##### Firewal Variables #####
# Firwall resource group
variable "az-ifw-rg" {
  default = "aan-terraform-ifw-rg"
}

#Firewall availability set
variable "az-ifw-as" {
  default = "aan-ifw-as"
}

# Management pulic IP for both VMs
variable "az-ifw1-mgnt-pip" {
  default = "aan-tf-ifw1-mgnt-pip"
}
variable "az-ifw2-mgnt-pip" {
  default = "aan-tf-ifw2-mgnt-pip"
}

# nic0 for both VMs
variable "az-ifw1-nic0" {
  default = "aan-tf-ifw1-nic0"
}
variable "az-ifw2-nic0" {
  default = "aan-tf-ifw2-nic0"
}

# nic1 for both VMs
variable "az-ifw1-nic1" {
  default = "aan-tf-ifw1-nic1"
}
variable "az-ifw2-nic1" {
  default = "aan-tf-ifw2-nic1"
}

# nic2 for both VMs
variable "az-ifw1-nic2" {
  default = "aan-tf-ifw1-nic2"
}
variable "az-ifw2-nic2" {
  default = "aan-tf-ifw2-nic2"
}

# Name for both VMs
# No "-" in PAN name
variable "az-pan-ifw1-name" {
  default = "aantfifw1"
}
variable "az-pan-ifw2-name" {
  default = "aantfifw2"
}

# Disk name for both VMs
variable "az-ifw1-disk-name" {
  default = "aan-ifw1-disk"
}
variable "az-ifw2-disk-name" {
  default = "aan-ifw2-disk"
}

variable "az-ifw-size" {
  default = "Standard_DS3_v2"
}

# To use a pay as you go license set name to "bundle1" or "bundle2"
# To use a purchased license change name to "byol"
variable "az-ifw-sku" {
  default = "byol"
}

###### End of Variables #######

#Create Subnets
resource "azurerm_subnet" "ifw-untrust-subnet" {
  name                 = "ifw-untrust-subnet"
  resource_group_name  = azurerm_resource_group.vnet-rg.name
  virtual_network_name = azurerm_virtual_network.main-vnet.name
  address_prefixes     = var.ifw-untrust-adx
}
resource "azurerm_subnet" "ifw-trust-subnet" {
  name                 = "ifw-trust-subnet"
  resource_group_name  = azurerm_resource_group.vnet-rg.name
  virtual_network_name = azurerm_virtual_network.main-vnet.name
  address_prefixes     = var.ifw-trust-adx
}
resource "azurerm_subnet" "ifw-mgnt-subnet" {
  name                 = "ifw-mgnt-subnet"
  resource_group_name  = azurerm_resource_group.vnet-rg.name
  virtual_network_name = azurerm_virtual_network.main-vnet.name
  address_prefixes     = var.ifw-mgnt-adx
}

# Create Network Security Groups
resource "azurerm_network_security_group" "ifw-untrust-nsg" {
  name                = var.az-ifw-untrust-nsg
  location            = azurerm_resource_group.vnet-rg.location
  resource_group_name = azurerm_resource_group.ifw-rg.name
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
resource "azurerm_network_security_group" "ifw-trust-nsg" {
  name                = var.az-ifw-trust-nsg
  location            = azurerm_resource_group.vnet-rg.location
  resource_group_name = azurerm_resource_group.ifw-rg.name
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
resource "azurerm_network_security_group" "ifw-mgnt-nsg" {
  name                = var.az-ifw-mgnt-nsg
  location            = azurerm_resource_group.vnet-rg.location
  resource_group_name = azurerm_resource_group.ifw-rg.name
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
resource "azurerm_subnet_network_security_group_association" "ifw-untrust-nsg-assoc" {
  subnet_id                 = azurerm_subnet.ifw-untrust-subnet.id
  network_security_group_id = azurerm_network_security_group.ifw-untrust-nsg.id
}
resource "azurerm_subnet_network_security_group_association" "ifw-trust-nsg-assoc" {
  subnet_id                 = azurerm_subnet.ifw-trust-subnet.id
  network_security_group_id = azurerm_network_security_group.ifw-trust-nsg.id
}
resource "azurerm_subnet_network_security_group_association" "ifw-mgnt-nsg-assoc" {
  subnet_id                 = azurerm_subnet.ifw-mgnt-subnet.id
  network_security_group_id = azurerm_network_security_group.ifw-mgnt-nsg.id
}

##############################################################
# Create PAN Firewalls VM & Required Resources

# Create ifw Resource Group
resource "azurerm_resource_group" "ifw-rg" {
  name     = var.az-ifw-rg
  location = var.az-region
}

# Create Availability Set to place both firewalls in.
# If using availability-sets both VMs have to be in the same resource group
resource "azurerm_availability_set" "ifw-as" {
  name                         = var.az-ifw-as
  location                     = azurerm_resource_group.ifw-rg.location
  resource_group_name          = azurerm_resource_group.ifw-rg.name
  platform_fault_domain_count  = 2
  platform_update_domain_count = 2
  managed                      = true
}


##### Create First VM #####
# Create three NICs with IPs for firewall VM
resource "azurerm_public_ip" "ifw1-mgnt-pip" {
  name                = var.az-ifw1-mgnt-pip
  location            = azurerm_resource_group.ifw-rg.location
  resource_group_name = azurerm_resource_group.ifw-rg.name
  allocation_method   = "Static"
  sku                 = "Standard"   
}

resource "azurerm_network_interface" "ifw1-nic0" {
  name                   = var.az-ifw1-nic0
  location               = azurerm_resource_group.ifw-rg.location
  resource_group_name    = azurerm_resource_group.ifw-rg.name
  depends_on             = [azurerm_virtual_network.main-vnet]

  ip_configuration {
    name                          = "mgnt-ip"
    subnet_id                     = azurerm_subnet.ifw-mgnt-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.ifw1-mgnt-pip.id
  }
}

resource "azurerm_network_interface" "ifw1-nic1" {
  name                   = var.az-ifw1-nic1
  location               = azurerm_resource_group.ifw-rg.location
  resource_group_name    = azurerm_resource_group.ifw-rg.name
  depends_on             = [azurerm_virtual_network.main-vnet]
  enable_ip_forwarding   = true
  enable_accelerated_networking = true

  ip_configuration {
    name                          = "untrust-ip"
    subnet_id                     = azurerm_subnet.ifw-untrust-subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface" "ifw1-nic2" {
  name                   = var.az-ifw1-nic2
  location               = azurerm_resource_group.ifw-rg.location
  resource_group_name    = azurerm_resource_group.ifw-rg.name
  depends_on             = [azurerm_virtual_network.main-vnet]
  enable_ip_forwarding = true
  enable_accelerated_networking = true

  ip_configuration {
    name                          = "trust-ip"
    subnet_id                     = azurerm_subnet.ifw-trust-subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_machine" "pan-ifw1" {
  name                         = var.az-pan-ifw1-name
  location                     = azurerm_resource_group.ifw-rg.location
  resource_group_name          = azurerm_resource_group.ifw-rg.name
  availability_set_id          = azurerm_availability_set.ifw-as.id
  vm_size                      = var.az-ifw-size
  primary_network_interface_id = azurerm_network_interface.ifw1-nic0.id
  network_interface_ids        = [azurerm_network_interface.ifw1-nic0.id, 
                                  azurerm_network_interface.ifw1-nic1.id, 
                                  azurerm_network_interface.ifw1-nic2.id]
  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  # To use a pay as you go license set name to "bundle1" or "bundle2"
  # To use a purchased license change name to "byol"
  plan {
    name      = var.az-ifw-sku
    publisher = "paloaltonetworks"
    product   = "vmseries-flex"
  }

  # to use a pay as you go license set sku to "bundle1" or "bundle2"
  # To use a purchased license change sku to "byol"
  storage_image_reference {
    publisher = "paloaltonetworks"
    offer     = "vmseries-flex"
    sku       = var.az-ifw-sku
    version   = "latest"
  }

  storage_os_disk {
    name              = var.az-ifw1-disk-name
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = var.az-pan-ifw1-name
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
resource "azurerm_public_ip" "ifw2-mgnt-pip" {
  name                = var.az-ifw2-mgnt-pip
  location            = azurerm_resource_group.ifw-rg.location
  resource_group_name = azurerm_resource_group.ifw-rg.name
  allocation_method   = "Static"
  sku                 = "Standard"   
}

resource "azurerm_network_interface" "ifw2-nic0" {
  name                   = var.az-ifw2-nic0
  location               = azurerm_resource_group.ifw-rg.location
  resource_group_name    = azurerm_resource_group.ifw-rg.name
  depends_on             = [azurerm_virtual_network.main-vnet]

  ip_configuration {
    name                          = "mgnt-ip"
    subnet_id                     = azurerm_subnet.ifw-mgnt-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.ifw2-mgnt-pip.id
  }
}

resource "azurerm_network_interface" "ifw2-nic1" {
  name                   = var.az-ifw2-nic1
  location               = azurerm_resource_group.ifw-rg.location
  resource_group_name    = azurerm_resource_group.ifw-rg.name
  depends_on             = [azurerm_virtual_network.main-vnet]
  enable_ip_forwarding   = true
  enable_accelerated_networking = true

  ip_configuration {
    name                          = "untrust-ip"
    subnet_id                     = azurerm_subnet.ifw-untrust-subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface" "ifw2-nic2" {
  name                   = var.az-ifw2-nic2
  location               = azurerm_resource_group.ifw-rg.location
  resource_group_name    = azurerm_resource_group.ifw-rg.name
  depends_on             = [azurerm_virtual_network.main-vnet]
  enable_ip_forwarding = true
  enable_accelerated_networking = true

  ip_configuration {
    name                          = "trust-ip"
    subnet_id                     = azurerm_subnet.ifw-trust-subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_machine" "pan-ifw2" {
  name                         = var.az-pan-ifw2-name
  location                     = azurerm_resource_group.ifw-rg.location
  resource_group_name          = azurerm_resource_group.ifw-rg.name
  availability_set_id          = azurerm_availability_set.ifw-as.id
  vm_size                      = var.az-ifw-size
  primary_network_interface_id = azurerm_network_interface.ifw2-nic0.id
  network_interface_ids        = [azurerm_network_interface.ifw2-nic0.id, 
                                  azurerm_network_interface.ifw2-nic1.id, 
                                  azurerm_network_interface.ifw2-nic2.id]
  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  # To use a pay as you go license set name to "bundle1" or "bundle2"
  # To use a purchased license change name to "byol"
  plan {
    name      = var.az-ifw-sku
    publisher = "paloaltonetworks"
    product   = "vmseries-flex"
  }

  # to use a pay as you go license set sku to "bundle1" or "bundle2"
  # To use a purchased license change sku to "byol"
  storage_image_reference {
    publisher = "paloaltonetworks"
    offer     = "vmseries-flex"
    sku       = var.az-ifw-sku
    version   = "latest"
  }

  storage_os_disk {
    name              = var.az-ifw2-disk-name
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = var.az-pan-ifw2-name
    # Note: admin_username cannot be "admin"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}