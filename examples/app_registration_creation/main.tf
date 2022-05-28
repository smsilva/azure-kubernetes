resource "random_string" "id" {
  length      = 3
  min_lower   = 1
  min_numeric = 2
  lower       = true
  special     = false
}

locals {
  azuread_application_name            = "argocd-wasp-sandbox-basic-${random_string.id.result}"
  azuread_application_domain          = "sandbox.wasp.silvios.me"
  azure_key_vault_name                = "waspfoundation636a465c"
  azure_key_vault_resource_group_name = "wasp-foundation"
}

data "azurerm_key_vault" "default" {
  name                = local.azure_key_vault_name
  resource_group_name = local.azure_key_vault_resource_group_name
}

module "argocd_app_registration" {
  source = "../../src/active_directory/app_registration"

  name   = local.azuread_application_name
  domain = local.azuread_application_domain
}

module "secrets" {
  source = "git@github.com:smsilva/azure-key-vault.git//src/secret?ref=1.0.0"

  vault = data.azurerm_key_vault.default
  key   = module.argocd_app_registration.password_id
  value = module.argocd_app_registration.password_value
}

output "password_id" {
  value     = module.argocd_app_registration.password_id
  sensitive = true
}

output "password_value" {
  value     = module.argocd_app_registration.password_value
  sensitive = true
}
