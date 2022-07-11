data "azurerm_client_config" "current" {}

resource "random_string" "id" {
  length      = 3
  min_lower   = 1
  min_numeric = 2
  lower       = true
  special     = false
}

variable "arm_client_secret" {
  type        = string
  description = "(Required) Azure Resource Manager Service Principal Client Secret (ARM_CLIENT_SECRET)"
  sensitive   = true
}
