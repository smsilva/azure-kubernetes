data "azurerm_key_vault" "default" {
  name                = var.keyvault_name
  resource_group_name = var.keyvault_resource_group_name
}

module "secrets" {
  source = "git@github.com:smsilva/azure-key-vault.git//src/secrets?ref=0.4.0"

  vault = data.azurerm_key_vault.default
  values = {
    "cluster-name"                          = module.aks.instance.name,
    "cluster-api-server-host"               = module.aks.instance.kube_admin_config[0].host,
    "cluster-api-server-token"              = module.aks.instance.kube_admin_config[0].password,
    "cluster-api-server-ca-certificate"     = module.aks.instance.kube_admin_config[0].cluster_ca_certificate,
    "cluster-api-server-credentials-argocd" = <<-EOT
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
    module.vnet
  ]
}
