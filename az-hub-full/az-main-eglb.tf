/*
Create Azure Internal Load Balancer for Egress Firewall NVA
*/

# Varibles for eglb
variable "az-eglb" {
  type = map
  default = {
    "name" = "aan-tf-eglb"
    "feip-name" = "aan-eglb-fe-ip"  #Front-end IP name
    "feip" = "10.100.1.4"  #Front-end IP address
    "be-pool-eglbadx1" = "10.100.1.5" #Back-end pool fw1-trust-nic-ip
    "be-pool-eglbadx2" = "10.100.1.6" #Back-end pool fw2-trust-nic-ip
  }
}


###### Create Egress Load Balancer #####
resource "azurerm_lb" "eglb" {
  name                = var.az-eglb["name"]
  location            = azurerm_resource_group.efw-rg.location
  resource_group_name = azurerm_resource_group.efw-rg.name
  sku                 = "Standard"

  frontend_ip_configuration {
      name                          = var.az-eglb["feip-name"]
      subnet_id                     = azurerm_subnet.efw-trust-subnet.id
      private_ip_address_allocation = "Static"
      private_ip_address            = var.az-eglb["feip"]
      public_ip_address_id          = null
      zones                         = null
  }
}

# Create Backend Pool and addresses for eglb
resource "azurerm_lb_backend_address_pool" "eglb-be-pool" {
  name                = "eglb-be-pool-1"
  loadbalancer_id     = azurerm_lb.eglb.id
  depends_on          = [azurerm_lb.eglb]
}

resource "azurerm_lb_backend_address_pool_address" "eglbadx1" {
  name                    = "efw1-trust"
  backend_address_pool_id = azurerm_lb_backend_address_pool.eglb-be-pool.id
  virtual_network_id      = azurerm_virtual_network.main-vnet.id
  ip_address              = var.az-eglb["be-pool-eglbadx1"]
}

resource "azurerm_lb_backend_address_pool_address" "eglbadx2" {
  name                    = "efw2-trust"
  backend_address_pool_id = azurerm_lb_backend_address_pool.eglb-be-pool.id
  virtual_network_id      = azurerm_virtual_network.main-vnet.id
  ip_address              = var.az-eglb["be-pool-eglbadx2"]
}

# Create Health Probe for eglb
resource "azurerm_lb_probe" "eglb-probe" {
  name                = "eblb-health-prode-1"
  resource_group_name = azurerm_resource_group.efw-rg.name
  loadbalancer_id     = azurerm_lb.eglb.id
  port                = "22"
  protocol            = "tcp"
  request_path        = null
  interval_in_seconds = "5"
  number_of_probes    = "2"
  depends_on          = [azurerm_lb.eglb]
}

resource "azurerm_lb_rule" "eglb-rule" {
  name                           = "eglb-rule-1"
  resource_group_name            = azurerm_resource_group.efw-rg.name
  loadbalancer_id                = azurerm_lb.eglb.id
  protocol                       = "All"
  frontend_port                  = "0"
  backend_port                   = "0"
  frontend_ip_configuration_name = var.az-eglb["feip-name"]
  backend_address_pool_id        = azurerm_lb_backend_address_pool.eglb-be-pool.id
  probe_id                       = azurerm_lb_probe.eglb-probe.id
  load_distribution              = null
  idle_timeout_in_minutes        = null
  enable_floating_ip             = true
  disable_outbound_snat          = true
  enable_tcp_reset               = false
  depends_on                     = [azurerm_lb.eglb, azurerm_lb_backend_address_pool.eglb-be-pool, azurerm_lb_probe.eglb-probe]
}


