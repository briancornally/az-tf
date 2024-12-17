output "rg_id" {
  value = data.azurerm_resource_group.this.id
}

output "vnet_id" {
  value = azurerm_virtual_network.this.id
}

output "db_subnet_id" {
  value = azurerm_subnet.db_subnet.id
}

output "web_subnet_id" {
  value = azurerm_subnet.web_subnet.id
}

output "web_nsg_id" {
  value = azurerm_network_security_group.web_nsg.id
}

output "azurerm_mssql_server_id" {
  value = azurerm_mssql_server.this.id
}

output "azurerm_mssql_database_id" {
  value = azurerm_mssql_database.this.id
}

# output "vm_id" {
#   value = azurerm_linux_virtual_machine.vm.id
# }
