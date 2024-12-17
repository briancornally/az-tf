module "vnet_name" {
  source         = "./modules/resource_naming"
  prefix         = local.cfg.prefix
  env_name       = local.env_name
  location       = local.cfg.location
  resource_type  = "vnet"
  instance_index = "01"
}

resource "azurerm_virtual_network" "this" {
  name                = module.vnet_name.name
  address_space       = local.cfg.vnet.address_space
  location            = data.azurerm_resource_group.this.location
  resource_group_name = data.azurerm_resource_group.this.name
}

# Output the Virtual Network ID
