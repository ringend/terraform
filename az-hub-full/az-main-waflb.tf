

# Varibles for waflb
variable "az-waflb" {
  type = map
  default = {
    "name"            = "aan-tf-waflb"
    "feip-name"       = "aan-waflb-fe-ip"  #Front-end IP name
    "feip-pip-name"   = "aan-waflb-fe-pip"  #Front-end IP name
    "be-pool-adx1"    = "10.100.21.5" #Back-end pool fw1-untrust-nic-ip
    "be-pool-adx2"    = "10.100.21.6" #Back-end pool fw2-untrust-nic-ip
  }
}

# Create Ingress Load Balancer PIP
resource "azurerm_public_ip" "waflb-pip" {
  name                = var.az-waflb["feip-pip-name"]
  location            = azurerm_resource_group.waf-rg.location
  resource_group_name = azurerm_resource_group.waf-rg.name
  sku                 = "Standard"
  allocation_method   = "Static"
}

###### Create Egress Load Balancer #####
resource "azurerm_lb" "waflb" {
  name                = var.az-waflb["name"]
  location            = azurerm_resource_group.waf-rg.location
  resource_group_name = azurerm_resource_group.waf-rg.name
  sku                 = "Standard"

  frontend_ip_configuration {
      name                          = var.az-waflb["feip-name"]
      private_ip_address_allocation = null
      private_ip_address            = null
      public_ip_address_id          = azurerm_public_ip.waflb-pip.id
      zones                         = null
  }
}

# Create Backend Pool and addresses for waflb
resource "azurerm_lb_backend_address_pool" "waflb-be-pool" {
  name                = "waflb-be-pool-1"
  loadbalancer_id     = azurerm_lb.waflb.id
  depends_on          = [azurerm_lb.waflb]

/* #Not working
  backend_address     {
    name               = "waf1"
    virtual_network_id = azurerm_subnet.waf-untrust-subnet.id
    ip_address         = var.az-waflb["be-pool-adx1"]
  }
*/
}

/* #Not Working
resource "azurerm_lb_backend_address_pool_address" "adx1" {
  name                    = "waf1-trust"
  backend_address_pool_id = azurerm_lb_backend_address_pool.waflb-be-pool.id
  virtual_network_id      = azurerm_subnet.waf-untrust-subnet.id
  ip_address              = "10.100.11.5"
  #ip_address              = var.az-waflb["be-pool-adx1"]
}
*/


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

# Create HTTP Rule
resource "azurerm_lb_rule" "waflb-P80-rule" {
  name                           = "waflb-P80-rule"
  resource_group_name            = azurerm_resource_group.waf-rg.name
  loadbalancer_id                = azurerm_lb.waflb.id
  protocol                       = "TCP"
  frontend_port                  = "80"
  backend_port                   = "80"
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

# Create HTTP Rule
resource "azurerm_lb_rule" "waflb-P443-rule" {
  name                           = "waflb-P443-rule"
  resource_group_name            = azurerm_resource_group.waf-rg.name
  loadbalancer_id                = azurerm_lb.waflb.id
  protocol                       = "TCP"
  frontend_port                  = "443"
  backend_port                   = "443"
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
