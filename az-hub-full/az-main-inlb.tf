


# Varibles for inlb
variable "az-inlb" {
  type = map
  default = {
    "name"            = "aan-tf-inlb"
    "feip-name"       = "aan-inlb-fe-ip"  #Front-end IP name
    "feip-pip-name"   = "aan-inlb-fe-pip"  #Front-end IP name
    "be-pool-adx1"    = "10.100.11.5" #Back-end pool fw1-untrust-nic-ip
    "be-pool-adx2"    = "10.100.11.6" #Back-end pool fw2-untrust-nic-ip
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

/* #Not working
  backend_address     {
    name               = "ifw1"
    virtual_network_id = azurerm_subnet.ifw-untrust-subnet.id
    ip_address         = var.az-inlb["be-pool-adx1"]
  }
*/
}

/* #Not Working
resource "azurerm_lb_backend_address_pool_address" "adx1" {
  name                    = "ifw1-trust"
  backend_address_pool_id = azurerm_lb_backend_address_pool.inlb-be-pool.id
  virtual_network_id      = azurerm_subnet.ifw-untrust-subnet.id
  ip_address              = "10.100.11.5"
  #ip_address              = var.az-inlb["be-pool-adx1"]
}
*/


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


