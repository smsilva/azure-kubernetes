module "argocd_app_registration" {
  source = "git@github.com:smsilva/azure-kubernetes.git//src/active_directory/app_registration?ref=development"

  name     = "argocd-${module.aks.instance.name}"
  dns_zone = var.dns_zone

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
