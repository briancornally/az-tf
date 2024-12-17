# Azure Terraform Sample

- A Virtual Network (VNet) with two subnets: one for web servers and one for database servers
  - vnet & subnet address space specified in `cfg.env-${LOCATION_CODE}-${ENV_NAME}.yml`
  - web and db subnets
- A Network Security Group (NSG) controls inbound and outbound traffic to the web servers
  - allow HTTP and HTTPS traffic to the web servers subnet
- A Managed SQL Database for the application’s data
  - performance level specified with [cfg.global.yml](cfg.global.yml) `mssql.database_sku`
- Virtual Machine Scale Set where the application is going to run
- A Load Balancer distributes traffic across web servers in Virtual Machine Scale Set

## Naming Convention

`${prefix}-${env_name}-${location_code}-${resource_type}-${instance_index}`

see: [resource_naming module](modules/resource_naming/README.md)

## Procedure

### Select Workspace

- environment name

```bash
export TF_WORKSPACE=ne-dev
export TF_VAR_mssql_server_admin_password='xxx'
```

- location and environment are parsed from workspace name by terraform

###

## References

- https://github.com/Azure/terraform-azurerm-caf-enterprise-scale/blob/main/modules/connectivity/locals.geo_codes.tf.json region code lookup
- https://github.com/Azure/terraform/tree/master/quickstart/201-private-link-sql-database
- https://learn.microsoft.com/en-us/azure/private-link/create-private-endpoint-terraform?tabs=azure-cli
