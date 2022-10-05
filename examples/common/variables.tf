# this file is in the common directory

data "azurerm_client_config" "current" {}

data "azurerm_key_vault" "default" {
  name                = local.key_vault_name
  resource_group_name = local.key_vault_resource_group_name
}

resource "random_string" "id" {
  length      = 5
  min_lower   = 3
  min_numeric = 2
  lower       = true
  special     = false
}

module "variables" {
  source = "../../src/variables"
  script = "azure"
}

locals {
  arm_client_secret = module.variables.values.arm_client_secret
}
