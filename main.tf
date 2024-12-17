# Reference existing Resource Group
data "azurerm_resource_group" "this" {
  name = local.cfg.resource_group_name
}
