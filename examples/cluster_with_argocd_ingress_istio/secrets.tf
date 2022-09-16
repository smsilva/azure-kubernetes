module "argocd_app_registration_password" {
  source = "git@github.com:smsilva/azure-key-vault.git//src/secret?ref=1.0.0"

  vault = data.azurerm_key_vault.default
  key   = "argocd-oidc-azuread-${module.argocd_app_registration.instance.application_id}"
  value = module.argocd_app_registration.password
}
