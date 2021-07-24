/*
Create Azure Public Load Balancer for Ingress Firewall NVA
*/


# Varibles for inlb
variable "az-inlb" {
  type = map
  default = {
    "name"            = "aan-tf-inlb"
    "feip-name"       = "aan-inlb-fe-ip"  #Front-end IP name
    "feip-pip-name"   = "aan-inlb-fe-pip"  #Front-end IP name
    "be-pool-inlbadx1"    = "10.100.10.5" #Back-end pool fw1-external-nic-ip
    "be-pool-inlbadx2"    = "10.100.10.6" #Back-end pool fw2-external-nic-ip
  }
}

# Create Ingress Load Balancer PIP
resource "azurerm_public_ip" "inlb-pip" {
  name                = var.az-inlb["feip-pip-name"]
  location            = azurerm_resource_group.ifw-rg.location
  resource_group_name = azurerm_resource_group.ifw-rg.name
  sku                 = "Standard"
  allocation_method   = "Static"
}

###### Create Egress Load Balancer #####
resource "azurerm_lb" "inlb" {
  name                = var.az-inlb["name"]
  location            = azurerm_resource_group.ifw-rg.location
  resource_group_name = azurerm_resource_group.ifw-rg.name
  sku                 = "Standard"

  frontend_ip_configuration {
      name                          = var.az-inlb["feip-name"]
      private_ip_address_allocation = null
      private_ip_address            = null
      public_ip_address_id          = azurerm_public_ip.inlb-pip.id
      zones                         = null
  }
}

# Create Backend Pool and addresses for inlb
resource "azurerm_lb_backend_address_pool" "inlb-be-pool" {
  name                = "inlb-be-pool-1"
  loadbalancer_id     = azurerm_lb.inlb.id
  depends_on          = [azurerm_lb.inlb]
}

resource "azurerm_lb_backend_address_pool_address" "inlbadx1" {
  name                    = "infw1-untrust"
  backend_address_pool_id = azurerm_lb_backend_address_pool.eglb-be-pool.id
  virtual_network_id      = azurerm_virtual_network.main-vnet.id
  ip_address              = var.az-inlb["be-pool-inlbadx1"]
}

resource "azurerm_lb_backend_address_pool_address" "inlbadx2" {
  name                    = "infw2-untrust"
  backend_address_pool_id = azurerm_lb_backend_address_pool.eglb-be-pool.id
  virtual_network_id      = azurerm_virtual_network.main-vnet.id
  ip_address              = var.az-inlb["be-pool-inlbadx2"]
}

# Create Health Probe for inlb
resource "azurerm_lb_probe" "inlb-probe" {
  name                = "eblb-health-prode-1"
  resource_group_name = azurerm_resource_group.ifw-rg.name
  loadbalancer_id     = azurerm_lb.inlb.id
  port                = "22"
  protocol            = "tcp"
  request_path        = null
  interval_in_seconds = "5"
  number_of_probes    = "2"
  depends_on          = [azurerm_lb.inlb]
}

resource "azurerm_lb_rule" "inlb-rule" {
  name                           = "inlb-test-rule-1"
  resource_group_name            = azurerm_resource_group.ifw-rg.name
  loadbalancer_id                = azurerm_lb.inlb.id
  protocol                       = "TCP"
  frontend_port                  = "5555"
  backend_port                   = "5555"
  frontend_ip_configuration_name = var.az-inlb["feip-name"]
  backend_address_pool_id        = azurerm_lb_backend_address_pool.inlb-be-pool.id
  probe_id                       = azurerm_lb_probe.inlb-probe.id
  load_distribution              = null
  idle_timeout_in_minutes        = null
  enable_floating_ip             = true
  disable_outbound_snat          = true
  enable_tcp_reset               = false
  depends_on                     = [azurerm_lb.inlb, azurerm_lb_backend_address_pool.inlb-be-pool, azurerm_lb_probe.inlb-probe]
}


