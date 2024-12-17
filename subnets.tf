module "db_subnet_name" {
  source         = "./modules/resource_naming"
  prefix         = local.cfg.prefix
  env_name       = local.env_name
  location       = local.cfg.location
  resource_type  = "subnet"
  instance_index = "db"
}

resource "azurerm_subnet" "db_subnet" {
  name                 = module.db_subnet_name.name
  resource_group_name  = data.azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = local.cfg.vnet.subnets[0].address_prefixes
}


module "web_subnet_name" {
  source         = "./modules/resource_naming"
  prefix         = local.cfg.prefix
  env_name       = local.env_name
  location       = local.cfg.location
  resource_type  = "subnet"
  instance_index = "web"
}

resource "azurerm_subnet" "web_subnet" {
  name                 = module.web_subnet_name.name
  resource_group_name  = data.azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = local.cfg.vnet.subnets[1].address_prefixes

}

# Output the Subnet ID
