terraform {
  required_providers {
    azapi = {
      source  = "azure/azapi"
      version = "~>2"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4"
    }
    # https://github.com/isometry/terraform-provider-deepmerge
    deepmerge = {
      source  = "registry.terraform.io/isometry/deepmerge"
      version = "~>0.3"
    }
  }
}

provider "azurerm" {
  features {
  }
  use_msi  = false
  use_cli  = true
  use_oidc = true
}



provider "deepmerge" {}
