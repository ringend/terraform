/*
Create Azure Public Load Balancer for Web Application Firewall NVA
*/

# Varibles for waflb
variable "az-waflb" {
  type = map
  default = {
    "name"            = "aan-tf-waflb"
    "feip-name"       = "aan-waflb-fe-ip"  #Front-end IP name
    "feip"            = "10.100.20.4"  #Front-end IP address
    "be-pool-wafadx1"    = "10.100.20.5" #Back-end pool fw1-external-nic-ip
    "be-pool-wafadx2"    = "10.100.20.6" #Back-end pool fw2-external-nic-ip
  }
}


###### Create Egress Load Balancer #####
resource "azurerm_lb" "waflb" {
  name                = var.az-waflb["name"]
  location            = azurerm_resource_group.waf-rg.location
  resource_group_name = azurerm_resource_group.waf-rg.name
  sku                 = "Standard"

  frontend_ip_configuration {
      name                          = var.az-waflb["feip-name"]
      subnet_id                     = azurerm_subnet.waf-external-subnet.id
      private_ip_address_allocation = "Static"
      private_ip_address            = var.az-waflb["feip"]
      public_ip_address_id          = null
      zones                         = null
  }
}

# Create Backend Pool and addresses for waflb
resource "azurerm_lb_backend_address_pool" "waflb-be-pool" {
  name                = "waflb-be-pool-1"
  loadbalancer_id     = azurerm_lb.waflb.id
  depends_on          = [azurerm_lb.waflb]
}

resource "azurerm_lb_backend_address_pool_address" "wafadx1" {
  name                    = "waf1-external"
  backend_address_pool_id = azurerm_lb_backend_address_pool.waflb-be-pool.id
  virtual_network_id      = azurerm_virtual_network.main-vnet.id
  ip_address              = var.az-waflb["be-pool-wafadx1"]
}

resource "azurerm_lb_backend_address_pool_address" "wafadx2" {
  name                    = "waf2-external"
  backend_address_pool_id = azurerm_lb_backend_address_pool.waflb-be-pool.id
  virtual_network_id      = azurerm_virtual_network.main-vnet.id
  ip_address              = var.az-waflb["be-pool-wafadx2"]
}

# Create Health Probe for waflb
resource "azurerm_lb_probe" "waflb-probe" {
  name                = "eblb-health-prode-1"
  resource_group_name = azurerm_resource_group.waf-rg.name
  loadbalancer_id     = azurerm_lb.waflb.id
  port                = "22"
  protocol            = "tcp"
  request_path        = null
  interval_in_seconds = "5"
  number_of_probes    = "2"
  depends_on          = [azurerm_lb.waflb]
}


# Create HA Port Rule
resource "azurerm_lb_rule" "waflb-rule" {
  name                           = "waflb-rule-1"
  resource_group_name            = azurerm_resource_group.waf-rg.name
  loadbalancer_id                = azurerm_lb.waflb.id
  protocol                       = "All"
  frontend_port                  = "0"
  backend_port                   = "0"
  frontend_ip_configuration_name = var.az-waflb["feip-name"]
  backend_address_pool_id        = azurerm_lb_backend_address_pool.waflb-be-pool.id
  probe_id                       = azurerm_lb_probe.waflb-probe.id
  load_distribution              = null
  idle_timeout_in_minutes        = null
  enable_floating_ip             = true
  disable_outbound_snat          = true
  enable_tcp_reset               = false
  depends_on                     = [azurerm_lb.waflb, azurerm_lb_backend_address_pool.waflb-be-pool, azurerm_lb_probe.waflb-probe]
}
