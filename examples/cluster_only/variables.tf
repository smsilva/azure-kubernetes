data "azurerm_client_config" "current" {}

resource "random_string" "id" {
  length      = 6
  min_lower   = 3
  min_numeric = 3
  lower       = true
  special     = false
}

variable "arm_client_secret" {
  type        = string
  description = "(Required) Azure Resource Manager Service Principal Client Secret (ARM_CLIENT_SECRET)"
  sensitive   = true
}
