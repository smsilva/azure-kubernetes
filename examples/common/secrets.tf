# this file is in the common directory

module "argocd_app_registration_password" {
  count = local.install_argocd ? 1 : 0

  source = "git@github.com:smsilva/azure-key-vault.git//src/secret?ref=1.0.0"

  vault = data.azurerm_key_vault.default
  key   = "argocd-oidc-azuread-${module.argocd_app_registration[0].instance.application_id}"
  value = module.argocd_app_registration[0].password
}
