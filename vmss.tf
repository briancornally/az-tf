# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/orchestrated_virtual_machine_scale_set

# Create storage account for boot diagnostics
module "vmss_diag_sa_name" {
  source         = "./modules/resource_naming"
  prefix         = local.cfg.prefix
  env_name       = local.env_name
  location       = local.cfg.location
  resource_type  = "sa"
  instance_index = "diag"
}

resource "azurerm_storage_account" "vmss_diag_sa" {
  name                     = replace(module.vmss_diag_sa_name.name, "-", "")
  location                 = data.azurerm_resource_group.this.location
  resource_group_name      = data.azurerm_resource_group.this.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = local.tags
}

module "vmss_name" {
  source         = "./modules/resource_naming"
  prefix         = local.cfg.prefix
  env_name       = local.env_name
  location       = local.cfg.location
  resource_type  = "vmss"
  instance_index = "01"
}

module "vmss_nic_name" {
  source         = "./modules/resource_naming"
  prefix         = local.cfg.prefix
  env_name       = local.env_name
  location       = local.cfg.location
  resource_type  = "vmss-nic"
  instance_index = "01"
}

resource "azurerm_orchestrated_virtual_machine_scale_set" "this" {
  name                        = module.vmss_name.name
  location                    = data.azurerm_resource_group.this.location
  resource_group_name         = data.azurerm_resource_group.this.name
  sku_name                    = local.cfg.vmss.sku_name
  instances                   = local.cfg.vmss.instances
  platform_fault_domain_count = 1     # For zonal deployments, this must be set to 1
  zones                       = ["1"] # Zones required to lookup zone in the startup script
  tags                        = local.tags
  # eviction_policy             = "Deallocate"
  # priority                    = "Spot"

  user_data_base64 = base64encode(file("web.conf"))
  os_profile {
    linux_configuration {
      disable_password_authentication = true
      admin_username                  = local.cfg.vmss.username
      admin_ssh_key {
        username   = local.cfg.vmss.username
        public_key = file("~/.ssh/az-tf.id_ed25519.pem.pub")
      }
    }
  }

  source_image_reference {
    publisher = local.cfg.vmss.image_publisher
    offer     = local.cfg.vmss.image_offer
    sku       = local.cfg.vmss.image_sku
    version   = local.cfg.vmss.image_version
  }
  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name                          = module.vmss_nic_name.name
    primary                       = true
    enable_accelerated_networking = false

    ip_configuration {
      name                                   = "ipconfig"
      primary                                = true
      subnet_id                              = azurerm_subnet.web_subnet.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.bepool.id]
    }
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.vmss_diag_sa.primary_blob_endpoint
  }

  # Ignore changes to the instances property, so that the VMSS is not recreated when the number of instances is changed
  lifecycle {
    ignore_changes = [
      instances
    ]
  }
}
