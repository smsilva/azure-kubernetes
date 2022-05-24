locals {
  cluster_name                    = var.cluster_name
  cluster_version                 = var.cluster_version
  cluster_admin_group_ids         = var.cluster_admin_group_ids
  cluster_resource_group_name     = var.cluster_resource_group_name != "" ? var.cluster_resource_group_name : local.cluster_name
  cluster_resource_group_location = var.cluster_location
  virtual_network_name            = local.cluster_name
  virtual_network_cidrs           = var.virtual_network_cidrs
  virtual_network_subnets         = var.virtual_network_subnets
}

resource "azurerm_resource_group" "default" {
  name     = local.cluster_resource_group_name
  location = var.cluster_location
}

module "vnet" {
  source = "git@github.com:smsilva/azure-network.git//src/vnet?ref=3.0.6"

  name                = local.virtual_network_name
  cidrs               = local.virtual_network_cidrs
  subnets             = local.virtual_network_subnets
  resource_group_name = azurerm_resource_group.default.name

  depends_on = [
    azurerm_resource_group.default
  ]
}

module "aks" {
  source = "git@github.com:smsilva/azure-kubernetes.git//src?ref=4.5.0"

  name                 = local.cluster_name
  orchestrator_version = local.cluster_version
  admin_id_list        = local.cluster_admin_group_ids
  subnet               = module.vnet.subnets["aks"].instance
  resource_group       = azurerm_resource_group.default

  depends_on = [
    module.vnet
  ]
}

module "argocd" {
  source = "git@github.com:smsilva/azure-kubernetes.git//src/argocd?ref=development"

  url                              = var.argocd_url
  cluster_instance                 = module.aks.instance
  install_cert_manager             = var.install_cert_manager
  install_external_secrets         = var.install_external_secrets
  install_external_dns             = var.install_external_dns
  install_nginx_ingress_controller = var.install_nginx_ingress_controller
  install_argocd                   = var.install_argocd
  argocd_rbac_group_admin          = var.argocd_rbac_group_admin
  argocd_rbac_group_contributor    = var.argocd_rbac_group_contributor
  ingress_issuer_name              = var.argocd_ingress_issuer_name
  armKeyVaultName                  = var.keyvault_name
  armClientSecret                  = var.armClientSecret

  depends_on = [
    module.aks
  ]
}
