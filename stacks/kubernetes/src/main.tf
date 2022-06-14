locals {
  cluster_base_name               = var.cluster_base_name
  cluster_name                    = "${var.cluster_name_prefix}${local.cluster_base_name}"
  cluster_resource_group_name     = local.cluster_name
  cluster_resource_group_location = var.cluster_location
  cluster_version                 = var.cluster_version
  cluster_node_pool_min_count     = var.cluster_default_node_pool_min_count
  cluster_node_pool_max_count     = var.cluster_default_node_pool_max_count
  cluster_node_pool_name          = var.cluster_default_node_pool_name
  cluster_administrators_ids      = var.cluster_administrators_ids
  virtual_network_name            = local.cluster_name
  virtual_network_cidrs           = var.virtual_network_cidrs
  virtual_network_subnets         = var.virtual_network_subnets
  install_cert_manager            = var.install_cert_manager
  install_external_secrets        = var.install_external_secrets
  install_external_dns            = var.install_external_dns
  install_ingress_nginx           = var.install_ingress_nginx
  install_argocd                  = var.install_argocd
  dns_zone                        = var.dns_zone
  argocd_host_base_name           = "${var.argocd_prefix}${local.cluster_base_name}"
  argocd_app_registration_name    = local.argocd_host_base_name
  argocd_administrators_ids       = var.argocd_administrators_ids
  argocd_contributors_ids         = var.argocd_contributors_ids
  key_vault_name                  = var.key_vault_name
  key_vault_resource_group_name   = var.key_vault_resource_group_name
  branch_name                     = "refactor"
}

resource "azurerm_resource_group" "default" {
  name     = local.cluster_resource_group_name
  location = var.cluster_location
}

module "aks" {
  source = "git@github.com:smsilva/azure-kubernetes.git//src/cluster?ref=refactor"

  name                 = local.cluster_name
  orchestrator_version = local.cluster_version
  administrators_ids   = local.cluster_administrators_ids
  node_pool_name       = local.cluster_node_pool_name
  node_pool_min_count  = local.cluster_node_pool_min_count
  node_pool_max_count  = local.cluster_node_pool_max_count
  resource_group       = azurerm_resource_group.default
  subnet               = module.vnet.subnets["aks"].instance

  depends_on = [
    module.vnet
  ]
}

module "argocd_app_registration" {
  source = "git@github.com:smsilva/azure-kubernetes.git//src/active-directory/app-registration?ref=refactor"

  name     = local.argocd_app_registration_name
  dns_zone = local.dns_zone
}

module "cert_manager" {
  count  = local.install_cert_manager ? 1 : 0
  source = "git@github.com:smsilva/azure-kubernetes.git//src/cert-manager?ref=refactor"

  depends_on = [
    module.aks
  ]
}

module "external_secrets" {
  count  = local.install_external_secrets ? 1 : 0
  source = "git@github.com:smsilva/azure-kubernetes.git//src/external-secrets?ref=refactor"

  tenant_id      = data.azurerm_client_config.current.tenant_id
  client_id      = data.azurerm_client_config.current.client_id
  client_secret  = var.ARM_CLIENT_SECRET
  key_vault_name = data.azurerm_key_vault.default.name

  depends_on = [
    module.aks
  ]
}

module "external_dns" {
  count  = local.install_external_dns ? 1 : 0
  source = "git@github.com:smsilva/azure-kubernetes.git//src/external-dns?ref=refactor"

  depends_on = [
    module.external_secrets
  ]
}

module "ingress_nginx" {
  count  = local.install_ingress_nginx ? 1 : 0
  source = "git@github.com:smsilva/azure-kubernetes.git//src/ingress-nginx?ref=refactor"

  cname = module.aks.instance.name

  depends_on = [
    module.aks
  ]
}

module "argo_cd" {
  count  = local.install_argocd ? 1 : 0
  source = "git@github.com:smsilva/azure-kubernetes.git//src/argo-cd?ref=refactor"

  cname              = local.argocd_host_base_name
  domain             = local.dns_zone
  tenant_id          = data.azurerm_client_config.current.tenant_id
  sso_application_id = module.argocd_app_registration.instance.application_id
  administrators_ids = local.argocd_administrators_ids
  contributors_ids   = local.argocd_contributors_ids

  depends_on = [
    module.argocd_app_registration,
    module.cert_manager,
    module.external_secrets,
    module.ingress_nginx,
  ]
}
