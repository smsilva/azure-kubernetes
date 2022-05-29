data "azurerm_key_vault" "default" {
  name                = local.key_vault_name
  resource_group_name = local.key_vault_resource_group_name
}

module "argocd_app_registration" {
  source = "../../src/active_directory/app_registration"

  name     = local.argocd_app_registration_name
  dns_zone = local.dns_zone
}

module "argocd_app_registration_password" {
  source = "git@github.com:smsilva/azure-key-vault.git//src/secret?ref=1.0.0"

  vault = data.azurerm_key_vault.default
  key   = "argocd-oidc-azuread-${module.argocd_app_registration.instance.application_id}"
  value = module.argocd_app_registration.password
}
