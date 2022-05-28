resource "random_string" "id" {
  length      = 3
  min_lower   = 1
  min_numeric = 2
  lower       = true
  special     = false
}

locals {
  dns_zone                            = "sandbox.wasp.silvios.me"
  cluster_name                        = "wasp-example-basic-${random_string.id.result}"
  cluster_location                    = "eastus2"
  cluster_version                     = "1.21.9"
  cluster_default_node_pool_min_count = 3
  cluster_default_node_pool_max_count = 10
  cluster_default_node_pool_name      = "npsys01"
  cluster_administrators_ids          = ["d5075d0a-3704-4ed9-ad62-dc8068c7d0e1"] # aks-administrator
  cluster_resource_group_name         = local.cluster_name
  virtual_network_name                = local.cluster_name
  virtual_network_cidrs               = ["10.244.0.0/14"]
  virtual_network_subnets             = [{ cidr = "10.246.0.0/16", name = "aks" }]
  azure_key_vault_name                = "waspfoundation636a465c"
  azure_key_vault_resource_group_name = "wasp-foundation"
  argocd_host                         = "argocd-${local.cluster_name}.${local.dns_zone}"
  argocd_ingress_issuer_name          = "letsencrypt-nginx-staging"
  argocd_contributors_ids             = ["2deb9d06-5807-4107-a5a6-94368f39d79f"] # aks-contributor
  argocd_administrators_ids = [
    "d5075d0a-3704-4ed9-ad62-dc8068c7d0e1", # aks-administrator
    "805a3d92-4178-4ad1-a0d6-70eae41a463a", # cloud-admin
  ]
}

module "aks" {
  source = "../../src/cluster"

  name                        = local.cluster_name
  orchestrator_version        = local.cluster_version
  administrators_ids          = local.cluster_administrators_ids
  default_node_pool_min_count = local.cluster_default_node_pool_min_count
  default_node_pool_name      = local.cluster_default_node_pool_name
  resource_group              = azurerm_resource_group.default
  subnet                      = module.vnet.subnets["aks"].instance

  depends_on = [
    module.vnet
  ]
}

module "argocd" {
  source = "../../src/argocd"

  cluster_instance                 = module.aks.instance
  install_cert_manager             = true
  install_external_secrets         = true
  install_external_dns             = true
  install_nginx_ingress_controller = true
  install_argocd                   = true
  argocd_host                      = local.argocd_host
  argocd_sso_application_id        = module.argocd_app_registration.instance.application_id
  argocd_ingress_issuer_name       = local.argocd_ingress_issuer_name
  argocd_administrators_ids        = local.argocd_administrators_ids
  argocd_contributors_ids          = local.argocd_contributors_ids
  armKeyVaultName                  = var.armKeyVaultName
  armClientSecret                  = var.armClientSecret

  depends_on = [
    module.aks,
    module.argocd_app_registration,
    module.argocd_app_registration_password
  ]
}
