locals {
  cluster_name                    = var.cluster_name
  cluster_version                 = var.cluster_version
  cluster_administrators_ids      = var.cluster_administrators_ids
  cluster_resource_group_name     = var.cluster_resource_group_name != "" ? var.cluster_resource_group_name : local.cluster_name
  cluster_resource_group_location = var.cluster_location
  virtual_network_name            = local.cluster_name
  virtual_network_cidrs           = var.virtual_network_cidrs
  virtual_network_subnets         = var.virtual_network_subnets
  argocd_host                     = "argocd-${local.cluster_name}.${var.dns_zone}"
}

resource "azurerm_resource_group" "default" {
  name     = local.cluster_resource_group_name
  location = var.cluster_location
}

module "aks" {
  source = "git@github.com:smsilva/azure-kubernetes.git//src/cluster?ref=development"

  name                 = local.cluster_name
  orchestrator_version = local.cluster_version
  administrators_ids   = local.cluster_administrators_ids
  subnet               = module.vnet.subnets["aks"].instance
  resource_group       = azurerm_resource_group.default

  depends_on = [
    module.vnet
  ]
}

module "argocd" {
  source = "git@github.com:smsilva/azure-kubernetes.git//src/argocd?ref=development"

  cluster_instance                 = module.aks.instance
  install_cert_manager             = var.install_cert_manager
  install_external_secrets         = var.install_external_secrets
  install_external_dns             = var.install_external_dns
  install_nginx_ingress_controller = var.install_nginx_ingress_controller
  install_argocd                   = var.install_argocd
  argocd_host                      = local.argocd_host
  argocd_sso_application_id        = module.argocd_app_registration.instance.application_id
  argocd_ingress_issuer_name       = var.argocd_ingress_issuer_name
  argocd_administrators_ids        = var.argocd_administrators_ids
  argocd_contributors_ids          = var.argocd_contributors_ids
  armKeyVaultName                  = var.key_vault_name
  armClientSecret                  = var.armClientSecret

  depends_on = [
    module.aks
  ]
}
