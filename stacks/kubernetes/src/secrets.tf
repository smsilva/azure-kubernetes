data "azurerm_key_vault" "default" {
  name                = var.keyvault_name
  resource_group_name = var.keyvault_name
}

module "secrets" {
  source = "git@github.com:smsilva/azure-key-vault.git//src/secrets?ref=0.4.0"

  vault = data.azurerm_key_vault.default
  values = {
    "${var.cluster_id}-name"                   = module.aks.instance.name,
    "${var.cluster_id}-api-host"               = module.aks.instance.kube_admin_config[0].host,
    "${var.cluster_id}-api-token"              = module.aks.instance.kube_admin_config[0].password,
    "${var.cluster_id}-api-ca-certificate"     = module.aks.instance.kube_admin_config[0].cluster_ca_certificate,
    "${var.cluster_id}-api-credentials-argocd" = <<-EOT
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
