data "azurerm_key_vault" "default" {
  name                = var.key_vault_name
  resource_group_name = var.key_vault_resource_group_name
}

module "secrets" {
  source = "git@github.com:smsilva/azure-key-vault.git//src/secrets?ref=0.4.0"

  vault = data.azurerm_key_vault.default
  values = {
    "aks-${local.cluster_name}-api-host"               = module.aks.instance.kube_admin_config[0].host,
    "aks-${local.cluster_name}-api-token"              = module.aks.instance.kube_admin_config[0].password,
    "aks-${local.cluster_name}-api-ca-certificate"     = module.aks.instance.kube_admin_config[0].cluster_ca_certificate,
    "aks-${local.cluster_name}-api-credentials-argocd" = <<-EOT
    {
      "bearerToken": "${module.aks.instance.kube_admin_config[0].password}",
      "tlsClientConfig": {
        "insecure": false,
        "caData": "${module.aks.instance.kube_admin_config[0].cluster_ca_certificate}"
      }
    }
    EOT
  }

  depends_on = [
    data.azurerm_key_vault.default,
    module.aks
  ]
}

module "argocd_app_registration_password" {
  source = "git@github.com:smsilva/azure-key-vault.git//src/secret?ref=1.0.0"

  vault = data.azurerm_key_vault.default
  key   = "argocd-oidc-azuread-${module.argocd_app_registration.instance.application_id}"
  value = module.argocd_app_registration.password
}
