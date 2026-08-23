data "azuread_client_config" "current" {}

resource "azuread_group" "default" {
  display_name            = var.name
  description             = var.description
  owners                  = [data.azuread_client_config.current.object_id]
  security_enabled        = true
  mail_enabled            = false
  prevent_duplicate_names = true
}
