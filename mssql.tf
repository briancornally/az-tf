## Create a Managed SQL Server

module "mssql_server_name" {
  source         = "./modules/resource_naming"
  prefix         = local.cfg.prefix
  env_name       = local.env_name
  location       = local.cfg.location
  resource_type  = "mssql-server"
  instance_index = "01"
}

resource "azurerm_mssql_server" "this" {
  name                          = module.mssql_server_name.name
  resource_group_name           = data.azurerm_resource_group.this.name
  location                      = data.azurerm_resource_group.this.location
  version                       = "12.0" # Default SQL Server version
  administrator_login           = local.cfg.mssql.admin_username
  administrator_login_password  = var.mssql_server_admin_password
  public_network_access_enabled = false
}

## Create a Managed SQL Database

module "mssql_database_name" {
  source         = "./modules/resource_naming"
  prefix         = local.cfg.prefix
  env_name       = local.env_name
  location       = local.cfg.location
  resource_type  = "mssql-database"
  instance_index = "01"
}

## Create an Azure Managed SQL Database
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/mssql_database
resource "azurerm_mssql_database" "this" {
  name                        = module.mssql_database_name.name
  server_id                   = azurerm_mssql_server.this.id
  collation                   = "SQL_Latin1_General_CP1_CI_AS" # Optional: default collation
  sku_name                    = local.cfg.mssql.database_sku
  min_capacity                = 0.5
  zone_redundant              = false
  auto_pause_delay_in_minutes = 60 # range (60 - 10080) and divisible by 10 - property is only settable for serverless databases
  storage_account_type        = "Local"
}

# Create private endpoint for SQL server
module "mssql_ep_name" {
  source         = "./modules/resource_naming"
  prefix         = local.cfg.prefix
  env_name       = local.env_name
  location       = local.cfg.location
  resource_type  = "mssql_ep"
  instance_index = "01"
}

resource "azurerm_private_endpoint" "mssql_ep" {
  name                = module.mssql_ep_name.name
  location            = data.azurerm_resource_group.this.location
  resource_group_name = data.azurerm_resource_group.this.name
  subnet_id           = azurerm_subnet.db_subnet.id

  private_service_connection {
    name                           = "mssql-private-serviceconnection"
    private_connection_resource_id = azurerm_mssql_server.this.id
    subresource_names              = ["sqlServer"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.this.id]
  }
}

# Create private DNS zone
resource "azurerm_private_dns_zone" "this" {
  name                = "privatelink.database.windows.net"
  resource_group_name = data.azurerm_resource_group.this.name
}

# Create virtual network link
resource "azurerm_private_dns_zone_virtual_network_link" "this" {
  name                  = "vnet-link"
  resource_group_name   = data.azurerm_resource_group.this.name
  private_dns_zone_name = azurerm_private_dns_zone.this.name
  virtual_network_id    = azurerm_virtual_network.this.id
}
