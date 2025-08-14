resource "azurerm_public_ip" "atlantis" {
  name                = "public-ip-atlantis"
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name

  allocation_method = "Static"
}

resource "azurerm_lb" "public" {
  name                = "lb-public-atlantis"
  resource_group_name = azurerm_resource_group.default.name
  location            = azurerm_resource_group.default.location

  frontend_ip_configuration {
    name                 = "public"
    public_ip_address_id = azurerm_public_ip.atlantis.id
  }
}

resource "azurerm_lb_backend_address_pool" "public" {
  name            = "public-atlantis-servers"
  loadbalancer_id = azurerm_lb.public.id
}

resource "azurerm_lb_probe" "public" {
  loadbalancer_id = azurerm_lb.public.id
  name            = "status"
  protocol        = "Tcp"
  port            = 4141
}

resource "azurerm_lb_rule" "http" {
  name                           = "http-api"
  loadbalancer_id                = azurerm_lb.public.id
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 4141
  frontend_ip_configuration_name = azurerm_lb.public.frontend_ip_configuration[0].name
  probe_id                       = azurerm_lb_probe.public.id

  backend_address_pool_ids = [
    azurerm_lb_backend_address_pool.public.id,
  ]
}
