data "azurerm_key_vault" "default" {
  name                = local.azure_key_vault_name
  resource_group_name = local.azure_key_vault_resource_group_name
}

module "argocd_app_registration" {
  source = "../../src/active_directory/app_registration"

  name     = "argocd-${module.aks.instance.name}"
  dns_zone = local.dns_zone

  depends_on = [
    module.aks
  ]
}

module "argocd_app_registration_password" {
  source = "git@github.com:smsilva/azure-key-vault.git//src/secret?ref=1.0.0"

  vault = data.azurerm_key_vault.default
  key   = "argocd-oidc-azuread-${module.argocd_app_registration.instance.application_id}"
  value = module.argocd_app_registration.password
}
