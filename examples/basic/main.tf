resource "random_string" "id" {
  length      = 3
  min_lower   = 1
  min_numeric = 2
  lower       = true
  special     = false
}

locals {
  virtual_network_cidrs               = ["10.244.0.0/14"]
  virtual_network_subnets             = [{ cidr = "10.246.0.0/16", name = "aks" }]
  virtual_network_name                = "wasp-example-${random_string.id.result}"
  cluster_name                        = "wasp-example-${random_string.id.result}"
  cluster_location                    = "eastus2"
  cluster_version                     = "1.21.9"
  cluster_resource_group_name         = "wasp-example-${random_string.id.result}"
  cluster_admin_id_list               = ["d5075d0a-3704-4ed9-ad62-dc8068c7d0e1"] # aks-administrator
  cluster_default_node_pool_name      = "npsys01"
  cluster_default_node_pool_min_count = 3
}

resource "azurerm_resource_group" "default" {
  name     = local.cluster_resource_group_name
  location = local.cluster_location
}

module "vnet" {
  source = "git@github.com:smsilva/azure-network.git//src/vnet?ref=3.0.6"

  name                = local.virtual_network_name
  cidrs               = local.virtual_network_cidrs
  subnets             = local.virtual_network_subnets
  resource_group_name = azurerm_resource_group.default.name
}

module "aks" {
  source = "../../src/cluster"

  name                        = local.cluster_name
  location                    = local.cluster_location
  orchestrator_version        = local.cluster_version
  admin_id_list               = local.cluster_admin_id_list
  default_node_pool_min_count = local.cluster_default_node_pool_min_count
  default_node_pool_name      = local.cluster_default_node_pool_name
  resource_group              = azurerm_resource_group.default
  subnet                      = module.vnet.subnets["aks"].instance

  depends_on = [
    azurerm_resource_group.default,
    module.vnet
  ]
}

module "argocd" {
  source = "../../src/argocd"

  url                              = "argocd.sandbox.wasp.silvios.me"
  install_cert_manager             = true
  install_external_secrets         = true
  install_external_dns             = true
  install_nginx_ingress_controller = false
  install_argocd                   = true
  argocd_rbac_group_admin          = "d5075d0a-3704-4ed9-ad62-dc8068c7d0e1" # aks-administrator
  argocd_rbac_group_contributor    = "2deb9d06-5807-4107-a5a6-94368f39d79f" # aks-contributor
  armKeyVaultName                  = var.armKeyVaultName
  armClientSecret                  = var.armClientSecret

  depends_on = [
    module.aks
  ]
}
