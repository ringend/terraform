/*
Palo Alto Egress Firewall and required resources.
Creates three NSGs and three subnets.
Assign the three NSGs assign to the three subnets. 
Creates two Palo Alto Firewalls and attaches it to the three subnets
```
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

###### Variables Start #######

variable "az-efw-untrust-nsg" {
  default = "aan-tf-efw-untrust-nsg"
}

variable "az-efw-trust-nsg" {
  default = "aan-tf-efw-trust-nsg"
}

variable "az-efw-mgnt-nsg" {
  default = "aan-tf-efw-mgnt-nsg"
}

variable "efw-untrust-adx" {
  default = ["10.100.0.0/24"]
}

variable "efw-trust-adx" {
  default = ["10.100.1.0/24"]
}

variable "efw-mgnt-adx" {
  default = ["10.100.2.0/24"]
}

##### Firewal Variables #####
# Firwall resource group
variable "az-efw-rg" {
  default = "aan-terraform-efw-rg"
}

#Firewall availability set
variable "az-efw-as" {
  default = "aan-efw-as"
}

# Management pulic IP for both VMs
variable "az-efw1-mgnt-pip" {
  default = "aan-tf-efw1-mgnt-pip"
}
variable "az-efw2-mgnt-pip" {
  default = "aan-tf-efw2-mgnt-pip"
}

# Untrust public IP for both VMs
variable "az-efw1-untrust-pip" {
  default = "aan-tf-efw1-untrust-pip"
}
variable "az-efw2-untrust-pip" {
  default = "aan-tf-efw2-untrust-pip"
}

# nic0 for both VMs
variable "az-efw1-nic0" {
  default = "aan-tf-efw1-nic0"
}
variable "az-efw2-nic0" {
  default = "aan-tf-efw2-nic0"
}

# nic1 for both VMs
variable "az-efw1-nic1" {
  default = "aan-tf-efw1-nic1"
}
variable "az-efw2-nic1" {
  default = "aan-tf-efw2-nic1"
}

# nic2 for both VMs
variable "az-efw1-nic2" {
  default = "aan-tf-efw1-nic2"
}
variable "az-efw2-nic2" {
  default = "aan-tf-efw2-nic2"
}

# Name for both VMs
# No "-" in PAN name
variable "az-pan-efw1-name" {
  default = "aantfefw1"
}
variable "az-pan-efw2-name" {
  default = "aantfefw2"
}

# Disk name for both VMs
variable "az-efw1-disk-name" {
  default = "aan-efw1-disk"
}
variable "az-efw2-disk-name" {
  default = "aan-efw2-disk"
}

variable "az-efw-size" {
  default = "Standard_D3_v2"
}

# To use a pay as you go license set name to "bundle1" or "bundle2"
# To use a purchased license change name to "byol"
variable "az-efw-sku" {
  default = "bundle1"
}

###### End of Variables #######

#Create Subnets
resource "azurerm_subnet" "efw-untrust-subnet" {
  name                 = "efw-untrust-subnet"
  resource_group_name  = azurerm_resource_group.vnet-rg.name
  virtual_network_name = azurerm_virtual_network.main-vnet.name
  address_prefixes     = var.efw-untrust-adx
}
resource "azurerm_subnet" "efw-trust-subnet" {
  name                 = "efw-trust-subnet"
  resource_group_name  = azurerm_resource_group.vnet-rg.name
  virtual_network_name = azurerm_virtual_network.main-vnet.name
  address_prefixes     = var.efw-trust-adx
}
resource "azurerm_subnet" "efw-mgnt-subnet" {
  name                 = "efw-mgnt-subnet"
  resource_group_name  = azurerm_resource_group.vnet-rg.name
  virtual_network_name = azurerm_virtual_network.main-vnet.name
  address_prefixes     = var.efw-mgnt-adx
}

# Create Network Security Groups
resource "azurerm_network_security_group" "efw-untrust-nsg" {
  name                = var.az-efw-untrust-nsg
  location            = azurerm_resource_group.efw-rg.location
  resource_group_name = azurerm_resource_group.efw-rg.name
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
resource "azurerm_network_security_group" "efw-trust-nsg" {
  name                = var.az-efw-trust-nsg
  location            = azurerm_resource_group.efw-rg.location
  resource_group_name = azurerm_resource_group.efw-rg.name
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
resource "azurerm_network_security_group" "efw-mgnt-nsg" {
  name                = var.az-efw-mgnt-nsg
  location            = azurerm_resource_group.efw-rg.location
  resource_group_name = azurerm_resource_group.efw-rg.name
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
resource "azurerm_subnet_network_security_group_association" "efw-untrust-nsg-assoc" {
  subnet_id                 = azurerm_subnet.efw-untrust-subnet.id
  network_security_group_id = azurerm_network_security_group.efw-untrust-nsg.id
}
resource "azurerm_subnet_network_security_group_association" "efw-trust-nsg-assoc" {
  subnet_id                 = azurerm_subnet.efw-trust-subnet.id
  network_security_group_id = azurerm_network_security_group.efw-trust-nsg.id
}
resource "azurerm_subnet_network_security_group_association" "efw-mgnt-nsg-assoc" {
  subnet_id                 = azurerm_subnet.efw-mgnt-subnet.id
  network_security_group_id = azurerm_network_security_group.efw-mgnt-nsg.id
}

##############################################################
# Create PAN Firewalls VM & Required Resources

# Create efw Resource Group
resource "azurerm_resource_group" "efw-rg" {
  name     = var.az-efw-rg
  location = var.az-region
}

# Create Availability Set to place both firewalls in.
# If using availability-sets both VMs have to be in the same resource group
resource "azurerm_availability_set" "efw-as" {
  name                         = var.az-efw-as
  location                     = azurerm_resource_group.efw-rg.location
  resource_group_name          = azurerm_resource_group.efw-rg.name
  platform_fault_domain_count  = 2
  platform_update_domain_count = 2
  managed                      = true
}


##### Create First VM #####
# Create three NICs with IPs for firewall VM
resource "azurerm_public_ip" "efw1-mgnt-pip" {
  name                = var.az-efw1-mgnt-pip
  location            = azurerm_resource_group.efw-rg.location
  resource_group_name = azurerm_resource_group.efw-rg.name
  allocation_method   = "Static"
  sku                 = "Standard"   
}

resource "azurerm_public_ip" "efw1-untrust-pip" {
  name                = var.az-efw1-untrust-pip
  location            = azurerm_resource_group.efw-rg.location
  resource_group_name = azurerm_resource_group.efw-rg.name
  allocation_method   = "Static"
  sku                 = "Standard"  
}

resource "azurerm_network_interface" "efw1-nic0" {
  name                   = var.az-efw1-nic0
  location               = azurerm_resource_group.efw-rg.location
  resource_group_name    = azurerm_resource_group.efw-rg.name
  depends_on             = [azurerm_virtual_network.main-vnet]

  ip_configuration {
    name                          = "mgnt-ip"
    subnet_id                     = azurerm_subnet.efw-mgnt-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.efw1-mgnt-pip.id
  }
}

resource "azurerm_network_interface" "efw1-nic1" {
  name                   = var.az-efw1-nic1
  location               = azurerm_resource_group.efw-rg.location
  resource_group_name    = azurerm_resource_group.efw-rg.name
  depends_on             = [azurerm_virtual_network.main-vnet]
  enable_ip_forwarding   = true
  enable_accelerated_networking = true

  ip_configuration {
    name                          = "untrust-ip"
    subnet_id                     = azurerm_subnet.efw-untrust-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.efw1-untrust-pip.id
  }
}

resource "azurerm_network_interface" "efw1-nic2" {
  name                   = var.az-efw1-nic2
  location               = azurerm_resource_group.efw-rg.location
  resource_group_name    = azurerm_resource_group.efw-rg.name
  depends_on             = [azurerm_virtual_network.main-vnet]
  enable_ip_forwarding = true
  enable_accelerated_networking = true

  ip_configuration {
    name                          = "trust-ip"
    subnet_id                     = azurerm_subnet.efw-trust-subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_machine" "pan-efw1" {
  name                         = var.az-pan-efw1-name
  location                     = azurerm_resource_group.efw-rg.location
  resource_group_name          = azurerm_resource_group.efw-rg.name
  availability_set_id          = azurerm_availability_set.efw-as.id
  vm_size                      = var.az-efw-size
  primary_network_interface_id = azurerm_network_interface.efw1-nic0.id
  network_interface_ids        = [azurerm_network_interface.efw1-nic0.id, 
                                  azurerm_network_interface.efw1-nic1.id, 
                                  azurerm_network_interface.efw1-nic2.id]
  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  # To use a pay as you go license set name to "bundle1" or "bundle2"
  # To use a purchased license change name to "byol"
  plan {
    name      = var.az-efw-sku
    publisher = "paloaltonetworks"
    product   = "vmseries-flex"
  }

  # to use a pay as you go license set sku to "bundle1" or "bundle2"
  # To use a purchased license change sku to "byol"
  storage_image_reference {
    publisher = "paloaltonetworks"
    offer     = "vmseries-flex"
    sku       = var.az-efw-sku
    version   = "latest"
  }

  storage_os_disk {
    name              = var.az-efw1-disk-name
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = var.az-pan-efw1-name
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
resource "azurerm_public_ip" "efw2-mgnt-pip" {
  name                = var.az-efw2-mgnt-pip
  location            = azurerm_resource_group.efw-rg.location
  resource_group_name = azurerm_resource_group.efw-rg.name
  allocation_method   = "Static"
  sku                 = "Standard"   
}

resource "azurerm_public_ip" "efw2-untrust-pip" {
  name                = var.az-efw2-untrust-pip
  location            = azurerm_resource_group.efw-rg.location
  resource_group_name = azurerm_resource_group.efw-rg.name
  allocation_method   = "Static"
  sku                 = "Standard"  
}

resource "azurerm_network_interface" "efw2-nic0" {
  name                   = var.az-efw2-nic0
  location               = azurerm_resource_group.efw-rg.location
  resource_group_name    = azurerm_resource_group.efw-rg.name
  depends_on             = [azurerm_virtual_network.main-vnet]

  ip_configuration {
    name                          = "mgnt-ip"
    subnet_id                     = azurerm_subnet.efw-mgnt-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.efw2-mgnt-pip.id
  }
}

resource "azurerm_network_interface" "efw2-nic1" {
  name                   = var.az-efw2-nic1
  location               = azurerm_resource_group.efw-rg.location
  resource_group_name    = azurerm_resource_group.efw-rg.name
  depends_on             = [azurerm_virtual_network.main-vnet]
  enable_ip_forwarding   = true
  enable_accelerated_networking = true

  ip_configuration {
    name                          = "untrust-ip"
    subnet_id                     = azurerm_subnet.efw-untrust-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.efw2-untrust-pip.id
  }
}

resource "azurerm_network_interface" "efw2-nic2" {
  name                   = var.az-efw2-nic2
  location               = azurerm_resource_group.efw-rg.location
  resource_group_name    = azurerm_resource_group.efw-rg.name
  depends_on             = [azurerm_virtual_network.main-vnet]
  enable_ip_forwarding = true
  enable_accelerated_networking = true

  ip_configuration {
    name                          = "trust-ip"
    subnet_id                     = azurerm_subnet.efw-trust-subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_machine" "pan-efw2" {
  name                         = var.az-pan-efw2-name
  location                     = azurerm_resource_group.efw-rg.location
  resource_group_name          = azurerm_resource_group.efw-rg.name
  availability_set_id          = azurerm_availability_set.efw-as.id
  vm_size                      = var.az-efw-size
  primary_network_interface_id = azurerm_network_interface.efw2-nic0.id
  network_interface_ids        = [azurerm_network_interface.efw2-nic0.id, 
                                  azurerm_network_interface.efw2-nic1.id, 
                                  azurerm_network_interface.efw2-nic2.id]
  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  # To use a pay as you go license set name to "bundle1" or "bundle2"
  # To use a purchased license change name to "byol"
  plan {
    name      = var.az-efw-sku
    publisher = "paloaltonetworks"
    product   = "vmseries-flex"
  }

  # to use a pay as you go license set sku to "bundle1" or "bundle2"
  # To use a purchased license change sku to "byol"
  storage_image_reference {
    publisher = "paloaltonetworks"
    offer     = "vmseries-flex"
    sku       = var.az-efw-sku
    version   = "latest"
  }

  storage_os_disk {
    name              = var.az-efw2-disk-name
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = var.az-pan-efw2-name
    # Note: admin_username cannot be "admin"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}