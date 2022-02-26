resource "random_string" "id" {
  length      = 3
  min_lower   = 1
  min_numeric = 2
  lower       = true
  special     = false
}

resource "azurerm_resource_group" "default" {
  name     = local.resource_group_name
  location = local.location
}

module "vnet" {
  source = "git@github.com:smsilva/azure-network.git//src/vnet?ref=3.0.5"

  name                = local.virtual_network_name
  cidrs               = local.virtual_network_cidrs
  subnets             = local.virtual_network_subnets
  resource_group_name = azurerm_resource_group.default.name

  depends_on = [
    azurerm_resource_group.default
  ]
}

data "azurerm_client_config" "current" {}

locals {
  keyvault_name = "waspfoundation${substr(data.azurerm_client_config.current.subscription_id, 0, 8)}"
}

data "azurerm_key_vault" "foundation" {
  name                = local.keyvault_name
  resource_group_name = "wasp-foundation"
}
