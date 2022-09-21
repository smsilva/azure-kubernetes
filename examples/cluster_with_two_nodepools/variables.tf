data "azurerm_client_config" "current" {}

resource "random_string" "id" {
  length      = 5
  min_lower   = 3
  min_numeric = 2
  lower       = true
  special     = false
}
