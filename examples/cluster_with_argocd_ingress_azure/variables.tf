data "azurerm_client_config" "current" {}

data "azurerm_key_vault" "default" {
  name                = local.key_vault_name
  resource_group_name = local.key_vault_resource_group_name
}

resource "random_string" "id" {
  length      = 8
  min_lower   = 2
  min_numeric = 6
  lower       = true
  special     = false
}

variable "arm_client_secret" {
  type        = string
  description = "(Required) Azure Resource Manager Service Principal Client Secret (ARM_CLIENT_SECRET)"
  sensitive   = true
}
