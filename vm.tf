# Description: This file contains the code to create a virtual machine in Azure.
# The code creates a virtual machine, a public IP address, a network security group, and a network interface.

## Create a Public IP Address

module "public_ip_name" {
  source         = "./modules/resource_naming"
  prefix         = local.cfg.prefix
  env_name       = local.env_name
  location       = local.cfg.location
  resource_type  = "pip"
  instance_index = "vm-01"
}

resource "azurerm_public_ip" "public_ip_vm" {
  name                = module.public_ip_name.name
  location            = data.azurerm_resource_group.this.location
  resource_group_name = data.azurerm_resource_group.this.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

## Create a Network Security Group and rule

# module "vm_nsg_name" {
#   source         = "./modules/resource_naming"
#   prefix         = local.cfg.prefix
#   env_name       = local.env_name
#   location       = local.cfg.location
#   resource_type  = "nsg"
#   instance_index = "vm-01"
# }

# resource "azurerm_network_security_group" "vm_nsg" {
#   name                = module.vm_nsg_name.name
#   location            = data.azurerm_resource_group.this.location
#   resource_group_name = data.azurerm_resource_group.this.name

#   security_rule {
#     name                       = "SSH"
#     priority                   = 1001
#     direction                  = "Inbound"
#     access                     = "Allow"
#     protocol                   = "Tcp"
#     source_port_range          = "*"
#     destination_port_range     = "22"
#     source_address_prefix      = "*"
#     destination_address_prefix = "*"
#   }
# }

## Create a Network Interface
module "vm_nic_name" {
  source         = "./modules/resource_naming"
  prefix         = local.cfg.prefix
  env_name       = local.env_name
  location       = local.cfg.location
  resource_type  = "nic"
  instance_index = "vm-01"
}

resource "azurerm_network_interface" "vm_nic" {
  name                = module.vm_nic_name.name
  location            = data.azurerm_resource_group.this.location
  resource_group_name = data.azurerm_resource_group.this.name

  ip_configuration {
    name                          = "ip_configuration"
    subnet_id                     = azurerm_subnet.web_subnet.id
    private_ip_address_allocation = "Static"
    public_ip_address_id          = azurerm_public_ip.public_ip_vm.id
  }
}

## Connect the security group to the network interface

# resource "azurerm_network_interface_security_group_association" "vm_nsg_association" {
#   network_interface_id      = azurerm_network_interface.vm_nic.id
#   network_security_group_id = azurerm_network_security_group.vm_nsg.id
# }

# Create storage account for boot diagnostics
module "vm_diag_sa_name" {
  source         = "./modules/resource_naming"
  prefix         = local.cfg.prefix
  env_name       = local.env_name
  location       = local.cfg.location
  resource_type  = "sa"
  instance_index = "diag"
}

resource "azurerm_storage_account" "vm_diag_sa" {
  name                     = replace(module.vm_diag_sa_name.name, "-", "")
  location                 = data.azurerm_resource_group.this.location
  resource_group_name      = data.azurerm_resource_group.this.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Create virtual machine
module "vm_name" {
  source         = "./modules/resource_naming"
  prefix         = local.cfg.prefix
  env_name       = local.env_name
  location       = local.cfg.location
  resource_type  = "nic"
  instance_index = "vm-01"
}

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/windows_virtual_machine
resource "azurerm_linux_virtual_machine" "vm" {
  name                  = module.vm_name.name
  location              = data.azurerm_resource_group.this.location
  resource_group_name   = data.azurerm_resource_group.this.name
  network_interface_ids = [azurerm_network_interface.vm_nic.id]
  size                  = local.cfg.vm.size

  os_disk {
    name                 = "OsDisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = local.cfg.vm.image_publisher
    offer     = local.cfg.vm.image_offer
    sku       = local.cfg.vm.image_sku
    version   = local.cfg.vm.image_version
  }

  admin_username = local.cfg.vm.username

  admin_ssh_key {
    username   = local.cfg.vm.username
    public_key = file("~/.ssh/az-tf.id_ed25519.pem.pub")
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.vm_diag_sa.primary_blob_endpoint
  }
}
