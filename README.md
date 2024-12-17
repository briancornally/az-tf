# Azure Terraform Sample

- A Virtual Network (VNet) with two subnets: one for web servers and one for database servers
  - vnet & subnet address space specified in `cfg.env-${LOCATION_CODE}-${ENV_NAME}.yml`
  - web and db subnets
- A Network Security Group (NSG) controls inbound and outbound traffic to the web servers
  - allow HTTP and HTTPS traffic to the web servers subnet
- A Managed SQL Database for the application’s data
  - performance level specified with [cfg.global.yml](cfg.global.yml) `mssql.database_sku`
- Virtual Machine Scale Set where the application is going to run
  - azurerm_orchestrated_virtual_machine_scale_set is the curr
- A Load Balancer distributes traffic across web servers in Virtual Machine Scale Set

## Naming Convention

`${prefix}-${env_name}-${location_code}-${resource_type}-${instance_index}`

- see: [resource_naming module](modules/resource_naming/README.md)
- this approach
  - increases the lines of code but minimizes the configuration
  - facilitates naming convention changes by recreate
- to accomodate inconsistent naming deprecate the resource_naming module and add the resource names to the yml configuration files

## Procedure

### Select Workspace

- location code and environment names are parsed from workspace name by terraform `vars.tf`

```bash
export TF_WORKSPACE=ne-dev
export TF_VAR_mssql_server_admin_password='xxx'
ssh-keygen -m PEM -t ed25519 -f ~/.ssh/az-tf.id_ed25519.pem
```

### Initialize

```bash
terraform init -upgrade -migrate-state -force-copy
```

### Apply

```bash
terraform apply -auto-approve
```

### Test - vm - ssh

```bash
VM_ID=$(terraform output -raw vm_id)
VM_PIP=$(az vm list-ip-addresses --ids $VM_ID --query "[].virtualMachine.network.publicIpAddresses[0].ipAddress" --output tsv)
VM_USERNAME=$(yq .vm.username cfg.global.yml)
ssh -i ~/.ssh/az-tf.id_ed25519.pem -o "StrictHostKeyChecking no" $VM_USERNAME@$VM_PIP
```

### Test - sqlcmd - test

- https://learn.microsoft.com/en-us/sql/tools/sqlcmd/sqlcmd-utility?view=sql-server-ver16&tabs=go%2Cwindows&pivots=cs1-bash
- https://learn.microsoft.com/en-us/azure/synapse-analytics/sql-data-warehouse/sql-data-warehouse-get-started-connect-sqlcmd

```bash
AZURERM_MSSQL_DATABASE_NAME=$(terraform output -raw azurerm_mssql_database_id | awk -F/ '{print $NF}')
AZURERM_MSSQL_SERVER_NAME=$(terraform output -raw azurerm_mssql_server_id | awk -F/ '{print $NF}')
MSSQL_ADMIN_USERNAME=$(yq .mssql.admin_username cfg.global.yml)
echo sqlcmd -S $AZURERM_MSSQL_SERVER_NAME.database.windows.net -d $AZURERM_MSSQL_DATABASE_NAME -U $MSSQL_ADMIN_USERNAME -P \'$TF_VAR_mssql_server_admin_password\' -I -Q \""SELECT name FROM sys.tables;"\" | tee private-sql.sh
scp -i ~/.ssh/az-tf.id_ed25519.pem -o "StrictHostKeyChecking no" private-sql.sh $VM_USERNAME@$VM_PIP:
ssh -i ~/.ssh/az-tf.id_ed25519.pem -o "StrictHostKeyChecking no" $VM_USERNAME@$VM_PIP sh private-sql.sh
```

### Test - sqlcmd - test

- ssh to VM & invoke:

```bash
curl https://packages.microsoft.com/keys/microsoft.asc | sudo tee /etc/apt/trusted.gpg.d/microsoft.asc
sudo add-apt-repository "$(wget -qO- https://packages.microsoft.com/config/ubuntu/20.04/prod.list)"
sudo apt-get update
sudo apt-get install sqlcmd
sh private-sql.sh
```

## References

- https://github.com/Azure/terraform-azurerm-caf-enterprise-scale/blob/main/modules/connectivity/locals.geo_codes.tf.json region code lookup
- https://github.com/Azure/terraform/tree/master/quickstart/201-private-link-sql-database
- https://github.com/hashicorp-education/learn-terraform-azure-scale-sets

<!--
- https://learn.microsoft.com/en-us/azure/developer/terraform/create-vm-scaleset-network-disks-hcl
- https://learn.microsoft.com/en-us/azure/private-link/create-private-endpoint-terraform?tabs=azure-cli -->
