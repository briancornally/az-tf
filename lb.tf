module "lb_pip_name" {
  source         = "./modules/resource_naming"
  prefix         = local.cfg.prefix
  env_name       = local.env_name
  location       = local.cfg.location
  resource_type  = "pip"
  instance_index = "lb-01"
}

# A public IP address for the load balancer
resource "azurerm_public_ip" "lb_pip" {
  name                = module.lb_pip_name.name
  location            = data.azurerm_resource_group.this.location
  resource_group_name = data.azurerm_resource_group.this.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
  domain_name_label   = data.azurerm_resource_group.this.name
  tags                = local.tags
}

module "lb_name" {
  source         = "./modules/resource_naming"
  prefix         = local.cfg.prefix
  env_name       = local.env_name
  location       = local.cfg.location
  resource_type  = "lb"
  instance_index = "01"
}

# A load balancer with a frontend IP configuration and a backend address pool
resource "azurerm_lb" "lb" {
  name                = module.lb_name.name
  location            = data.azurerm_resource_group.this.location
  resource_group_name = data.azurerm_resource_group.this.name
  sku                 = "Standard"
  frontend_ip_configuration {
    name                 = "PublicIP"
    public_ip_address_id = azurerm_public_ip.lb_pip.id
  }
  tags = local.tags
}

resource "azurerm_lb_backend_address_pool" "bepool" {
  name            = "BackendAddressPool"
  loadbalancer_id = azurerm_lb.lb.id
}

#set up load balancer rule from azurerm_lb.example frontend ip to azurerm_lb_backend_address_pool.bepool backend ip port 80 to port 80
resource "azurerm_lb_rule" "lb" {
  name                           = "http"
  loadbalancer_id                = azurerm_lb.lb.id
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "PublicIP"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.bepool.id]
  probe_id                       = azurerm_lb_probe.this.id
}

# set up load balancer probe to check if the backend is up
resource "azurerm_lb_probe" "this" {
  name            = "http-probe"
  loadbalancer_id = azurerm_lb.lb.id
  protocol        = "Http"
  port            = 80
  request_path    = "/"
}

# add lb nat rules to allow ssh access to the backend instances
resource "azurerm_lb_nat_rule" "ssh" {
  name                           = "ssh"
  resource_group_name            = data.azurerm_resource_group.this.name
  loadbalancer_id                = azurerm_lb.lb.id
  protocol                       = "Tcp"
  frontend_port_start            = 50000
  frontend_port_end              = 50119
  backend_port                   = 22
  frontend_ip_configuration_name = "PublicIP"
  backend_address_pool_id        = azurerm_lb_backend_address_pool.bepool.id
}

module "pip_natgw_name" {
  source         = "./modules/resource_naming"
  prefix         = local.cfg.prefix
  env_name       = local.env_name
  location       = local.cfg.location
  resource_type  = "nat"
  instance_index = "natgw"
}

resource "azurerm_public_ip" "natgw" {
  name                = module.pip_natgw_name.name
  location            = data.azurerm_resource_group.this.location
  resource_group_name = data.azurerm_resource_group.this.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1"]
  tags                = local.tags
}

module "nat_gateway_name" {
  source         = "./modules/resource_naming"
  prefix         = local.cfg.prefix
  env_name       = local.env_name
  location       = local.cfg.location
  resource_type  = "nat_gateway"
  instance_index = "01"
}

# add nat gateway to enable outbound traffic from the backend instances
resource "azurerm_nat_gateway" "this" {
  name                    = module.nat_gateway_name.name
  location                = data.azurerm_resource_group.this.location
  resource_group_name     = data.azurerm_resource_group.this.name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10
  zones                   = ["1"]
  tags                    = local.tags
}

resource "azurerm_subnet_nat_gateway_association" "this" {
  subnet_id      = azurerm_subnet.web_subnet.id
  nat_gateway_id = azurerm_nat_gateway.this.id
}

# add nat gateway public ip association
resource "azurerm_nat_gateway_public_ip_association" "this" {
  public_ip_address_id = azurerm_public_ip.natgw.id
  nat_gateway_id       = azurerm_nat_gateway.this.id
}
