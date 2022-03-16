locals {
  location = "eastus2"

  cluster_name    = "wasp-aks-example-3-${random_string.id.result}"
  cluster_version = "1.21.7"

  resource_group_name = local.cluster_name

  virtual_network_name  = local.cluster_name
  virtual_network_cidrs = ["10.244.0.0/14"]
  virtual_network_subnets = [
    { cidr = "10.246.0.0/16", name = "aks" }
  ]

  admin_group_ids = [
    "d5075d0a-3704-4ed9-ad62-dc8068c7d0e1" # aks-administrator
  ]
}

module "aks" {
  source = "../../src"

  cluster_name            = local.cluster_name
  cluster_location        = local.location
  cluster_version         = local.cluster_version
  cluster_subnet_id       = module.vnet.subnets["aks"].instance.id
  cluster_admin_group_ids = local.admin_group_ids
  resource_group_name     = azurerm_resource_group.default.name
  default_node_pool_name  = "sys01" # 12 Alphanumeric characters

  depends_on = [
    azurerm_resource_group.default,
    module.vnet
  ]
}

module "secrets" {
  source = "git@github.com:smsilva/azure-key-vault.git//src/secrets?ref=1.0.0"

  vault = data.azurerm_key_vault.foundation
  values = {
    "aks-name"                      = module.aks.instance.name,
    "aks-api-server-host"           = module.aks.instance.kube_admin_config[0].host,
    "aks-api-server-token"          = module.aks.instance.kube_admin_config[0].password,
    "aks-api-server-ca-certificate" = module.aks.instance.kube_admin_config[0].cluster_ca_certificate,
    "aks-argocd-credentials-config" = <<-EOT
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
