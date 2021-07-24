/*
Create the Infrastruture Service subnet and two DNS servers
*/

###### Variables Start #######
variable "az-infrasrv-nsg" {
  default = "aan-tf-infrasrv-nsg"
}

variable "infrasrv-adx" {
  default = ["10.100.10.0/24"]
}

variable "az-infrasrv-route-table" {
  default = "aan-tf-infrasrv-route-table"
}

# Setting the IP from the egress firewall load balancer
variable "az-egress-fw-lb-ip" {
  default = "10.100.8.4"
}

##### DNS Server Variables #####
# DNS SErver resource group
variable "az-infrasrv-rg" {
  default = "aan-terraform-infrasrv-rg"
}

#DNS Server availability set
variable "az-dns-as" {
  default = "aan-dns-as"
}

# nic0 for both VMs
variable "az-dns1-nic0" {
  default = "aan-tf-dns1-nic0"
}
variable "az-dns2-nic0" {
  default = "aan-tf-dns2-nic0"
}

variable "az-dns1-ip" {
  default = "10.100.10.240"
}
variable "az-dns2-ip" {
  default = "10.100.10.239"
}

# Name for both VMs
variable "az-dns1-name" {
  default = "aan-tf-dns1"
}
variable "az-dns2-name" {
  default = "aan-tf-dns2"
}

# Disk name for both VMs
variable "az-dns1-disk-name" {
  default = "aan-dns1-disk"
}
variable "az-dns2-disk-name" {
  default = "aan-dns2-disk"
}

# VM Size
variable "az-dns-size" {
  default = "Standard_D2S_v3"
}


###### End of Variables #######

#Create Subnet
resource "azurerm_subnet" "infrasrv-subnet" {
  name                 = "infrasrv-subnet"
  resource_group_name  = azurerm_resource_group.vnet-rg.name
  virtual_network_name = azurerm_virtual_network.main-vnet.name
  address_prefixes     = var.infrasrv-adx
}


# Create Network Security Groups
resource "azurerm_network_security_group" "infrasrv-nsg" {
  name                = var.az-infrasrv-nsg
  location            = azurerm_resource_group.infrasrv-rg.location
  resource_group_name = azurerm_resource_group.infrasrv-rg.name
security_rule {
    name                       = "dns-in"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "53"
    source_address_prefix      = "10.0.0.0/8"
    destination_address_prefix = "*"
  }
security_rule {
    name                       = "ad-f1-in"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "49152-65535"
    source_address_prefix      = "10.0.0.0/8"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "rdp-in"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "10.0.0.0/8"
    destination_address_prefix = "*"
  }
   security_rule {
    name                       = "ssh-in"
    priority                   = 1010
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "10.0.0.0/8"
    destination_address_prefix = "*"
  }
   security_rule {
    name                       = "icmp-in"
    priority                   = 1020
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "icmp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "10.0.0.0/8"
    destination_address_prefix = "*"
  }
}

# Create NSG to subnet associations
resource "azurerm_subnet_network_security_group_association" "infrasrv-nsg-assoc" {
  subnet_id                 = azurerm_subnet.infrasrv-subnet.id
  network_security_group_id = azurerm_network_security_group.infrasrv-nsg.id
}

# Create Route Table
resource "azurerm_route_table" "infrasrv-route-table" {
  name                          = var.az-infrasrv-route-table
  location                      = azurerm_resource_group.infrasrv-rg.location
  resource_group_name           = azurerm_resource_group.infrasrv-rg.name
  disable_bgp_route_propagation = false

  route {
    name           = "default-route"
    address_prefix = "0.0.0.0/0"
    next_hop_type  = "VirtualAppliance"
    # Next Hop address is the LB or the egress firewalls
    next_hop_in_ip_address = var.az-egress-fw-lb-ip
  }
}

# Creat Route Table Assiocation
resource "azurerm_subnet_route_table_association" "infrasrv-route-table-assoc" {
  subnet_id      = azurerm_subnet.infrasrv-subnet.id
  route_table_id = azurerm_route_table.infrasrv-route-table.id
}


##############################################################
# Create  DNS Servers VM & Required Resources

# Create efw Resource Group
resource "azurerm_resource_group" "infrasrv-rg" {
  name     = var.az-infrasrv-rg
  location = var.az-region
}

# Create Availability Set to place both DNS Servers in.
# If using availability-sets both VMs have to be in the same resource group
resource "azurerm_availability_set" "dns-as" {
  name                         = var.az-dns-as
  location                     = azurerm_resource_group.infrasrv-rg.location
  resource_group_name          = azurerm_resource_group.infrasrv-rg.name
  platform_fault_domain_count  = 2
  platform_update_domain_count = 2
  managed                      = true
}


##### Create First VM #####
# Create  NICs with  DNS Server VM

resource "azurerm_network_interface" "dns1-nic0" {
  name                   = var.az-dns1-nic0
  location               = azurerm_resource_group.infrasrv-rg.location
  resource_group_name    = azurerm_resource_group.infrasrv-rg.name
  depends_on             = [azurerm_virtual_network.main-vnet]

  ip_configuration {
    name                          = "ip-config-1"
    subnet_id                     = azurerm_subnet.infrasrv-subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.az-dns1-ip
  }
}


resource "azurerm_linux_virtual_machine" "dns-server1" {
  name                         = var.az-dns1-name
  location                     = azurerm_resource_group.infrasrv-rg.location
  resource_group_name          = azurerm_resource_group.infrasrv-rg.name
  availability_set_id          = azurerm_availability_set.dns-as.id
  size                         = var.az-dns-size
  network_interface_ids        = [azurerm_network_interface.dns1-nic0.id]

 os_disk {
        name              = var.az-dns1-disk-name
        caching           = "ReadWrite"
        storage_account_type = "Premium_LRS"
    }

    source_image_reference {
        publisher = "OpenLogic"
        offer     = "CentOS"
        sku       = "8_2"
        version   = "latest"
    }

  computer_name  = var.az-dns1-name
  admin_username = "testadmin"
  admin_password = "Password1234!"
  disable_password_authentication = false
}


#### Create Second VM #####
# Create NIC for DNS Server VM
resource "azurerm_network_interface" "dns2-nic0" {
  name                   = var.az-dns2-nic0
  location               = azurerm_resource_group.infrasrv-rg.location
  resource_group_name    = azurerm_resource_group.infrasrv-rg.name
  depends_on             = [azurerm_virtual_network.main-vnet]

  ip_configuration {
    name                          = "ip-config-1"
    subnet_id                     = azurerm_subnet.infrasrv-subnet.id
    private_ip_address_allocation = "static"
    private_ip_address            = var.az-dns2-ip
  }
}

# Create DNS VM
resource "azurerm_linux_virtual_machine" "dns-server2" {
  name                         = var.az-dns2-name
  location                     = azurerm_resource_group.infrasrv-rg.location
  resource_group_name          = azurerm_resource_group.infrasrv-rg.name
  availability_set_id          = azurerm_availability_set.dns-as.id
  size                         = var.az-dns-size
  network_interface_ids        = [azurerm_network_interface.dns2-nic0.id]

 os_disk {
        name              = var.az-dns2-disk-name
        caching           = "ReadWrite"
        storage_account_type = "Premium_LRS"
    }

    source_image_reference {
        publisher = "OpenLogic"
        offer     = "CentOS"
        sku       = "8_2"
        version   = "latest"
    }

  computer_name  = var.az-dns1-name
  admin_username = "testadmin"
  admin_password = "Password1234!"
  disable_password_authentication = false
}
