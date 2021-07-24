/*
Create Azure Internal Load Balancer for DNS Service
*/

# Varibles for infrasrvlb
variable "az-infrasrvlb" {
  type = map
  default = {
    "name" = "aan-tf-infrasrv-lb"
    "feip-name" = "aan-infrasrvlb-fe-ip"  #Front-end IP name
    "feip" = "10.100.10.254"  #Front-end IP address
    "be-pool-infrasrvlbadx1" = "10.100.10.240" #Back-end pool dns-1-nic-ip
    "be-pool-infrasrvlbadx2" = "10.100.10.239" #Back-end pooldns-2-nic-ip
  }
}


###### Create Egress Load Balancer #####
resource "azurerm_lb" "infrasrvlb" {
  name                = var.az-infrasrvlb["name"]
  location            = azurerm_resource_group.infrasrv-rg.location
  resource_group_name = azurerm_resource_group.infrasrv-rg.name
  sku                 = "Standard"

  frontend_ip_configuration {
      name                          = var.az-infrasrvlb["feip-name"]
      subnet_id                     = azurerm_subnet.infrasrv-subnet.id
      private_ip_address_allocation = "Static"
      private_ip_address            = var.az-infrasrvlb["feip"]
      public_ip_address_id          = null
      zones                         = null
  }
}

# Create Backend Pool and addresses for infrasrvlb
resource "azurerm_lb_backend_address_pool" "infrasrvlb-be-pool" {
  name                = "dns-be-pool-1"
  loadbalancer_id     = azurerm_lb.infrasrvlb.id
  depends_on          = [azurerm_lb.infrasrvlb]
}

resource "azurerm_lb_backend_address_pool_address" "infrasrvlbadx1" {
  name                    = "dns1"
  backend_address_pool_id = azurerm_lb_backend_address_pool.infrasrvlb-be-pool.id
  virtual_network_id      = azurerm_virtual_network.main-vnet.id
  ip_address              = var.az-infrasrvlb["be-pool-infrasrvlbadx1"]
}

resource "azurerm_lb_backend_address_pool_address" "infrasrvlbadx2" {
  name                    = "dns2"
  backend_address_pool_id = azurerm_lb_backend_address_pool.infrasrvlb-be-pool.id
  virtual_network_id      = azurerm_virtual_network.main-vnet.id
  ip_address              = var.az-infrasrvlb["be-pool-infrasrvlbadx2"]
}

# Create Health Probe for infrasrvlb
resource "azurerm_lb_probe" "infrasrvlb-probe" {
  name                = "dns-health-prode-1"
  resource_group_name = azurerm_resource_group.infrasrv-rg.name
  loadbalancer_id     = azurerm_lb.infrasrvlb.id
  port                = "53"
  protocol            = "tcp"
  request_path        = null
  interval_in_seconds = "5"
  number_of_probes    = "2"
  depends_on          = [azurerm_lb.infrasrvlb]
}

resource "azurerm_lb_rule" "infrasrvlb-dns-udp" {
  name                           = "dns-udp"
  resource_group_name            = azurerm_resource_group.infrasrv-rg.name
  loadbalancer_id                = azurerm_lb.infrasrvlb.id
  protocol                       = "udp"
  frontend_port                  = "53"
  backend_port                   = "53"
  frontend_ip_configuration_name = var.az-infrasrvlb["feip-name"]
  backend_address_pool_id        = azurerm_lb_backend_address_pool.infrasrvlb-be-pool.id
  probe_id                       = azurerm_lb_probe.infrasrvlb-probe.id
  load_distribution              = null
  idle_timeout_in_minutes        = null
  enable_floating_ip             = false
  disable_outbound_snat          = true
  enable_tcp_reset               = false
  depends_on                     = [azurerm_lb.infrasrvlb, azurerm_lb_backend_address_pool.infrasrvlb-be-pool, azurerm_lb_probe.infrasrvlb-probe]
}

resource "azurerm_lb_rule" "infrasrvlb-dns-tcp" {
  name                           = "dns-tcp"
  resource_group_name            = azurerm_resource_group.infrasrv-rg.name
  loadbalancer_id                = azurerm_lb.infrasrvlb.id
  protocol                       = "tcp"
  frontend_port                  = "53"
  backend_port                   = "53"
  frontend_ip_configuration_name = var.az-infrasrvlb["feip-name"]
  backend_address_pool_id        = azurerm_lb_backend_address_pool.infrasrvlb-be-pool.id
  probe_id                       = azurerm_lb_probe.infrasrvlb-probe.id
  load_distribution              = null
  idle_timeout_in_minutes        = null
  enable_floating_ip             = false
  disable_outbound_snat          = true
  enable_tcp_reset               = false
  depends_on                     = [azurerm_lb.infrasrvlb, azurerm_lb_backend_address_pool.infrasrvlb-be-pool, azurerm_lb_probe.infrasrvlb-probe]
}

