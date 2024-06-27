locals {
  cluster_version             = "1.28.9"
  cluster_node_pool_min_count = 1
  cluster_node_pool_max_count = 5
  install_cert_manager        = false
  install_external_secrets    = false
  install_external_dns        = false
  install_ingress_nginx       = false
  install_argocd              = false
  install_app_of_apps_infra   = false
  cluster_ingress_type        = "nginx"
}

resource "azurerm_resource_group" "default" {
  name     = local.cluster_resource_group_name
  location = local.cluster_resource_group_location
}

module "aks" {
  source = "../../src/cluster"

  name                                   = local.cluster_name
  orchestrator_version                   = local.cluster_version
  administrators_ids                     = local.cluster_administrators_ids
  node_pool_name                         = local.cluster_node_pool_name
  node_pool_min_count                    = local.cluster_node_pool_min_count
  node_pool_max_count                    = local.cluster_node_pool_max_count
  resource_group                         = azurerm_resource_group.default
  subnet                                 = module.vnet.subnets["aks"].instance
  node_pool_only_critical_addons_enabled = false

  depends_on = [
    module.vnet
  ]
}

module "cert_manager" {
  count  = local.install_cert_manager ? 1 : 0
  source = "../../src/helm/modules/cert-manager"

  fqdn = local.cert_manager_fqdn

  depends_on = [
    module.aks
  ]
}

module "external_secrets" {
  count  = local.install_external_secrets ? 1 : 0
  source = "../../src/helm/modules/external-secrets"

  tenant_id      = data.azurerm_client_config.current.tenant_id
  client_id      = data.azurerm_client_config.current.client_id
  client_secret  = local.arm_client_secret
  key_vault_name = data.azurerm_key_vault.default.name

  depends_on = [
    module.aks
  ]
}

module "external_dns" {
  count  = local.install_external_dns ? 1 : 0
  source = "../../src/helm/modules/external-dns"

  domain         = local.dns_zone
  tenantId       = data.azurerm_client_config.current.tenant_id
  subscriptionId = data.azurerm_subscription.current.subscription_id
  resourceGroup  = local.dns_zone_resource_group_name

  depends_on = [
    azurerm_role_assignment.kubelet_contributor_on_dns_zone
  ]
}

module "ingress_nginx" {
  count  = local.install_ingress_nginx ? 1 : 0
  source = "../../src/helm/modules/ingress-nginx"

  cname  = local.cname_record_ingress
  domain = local.dns_zone

  depends_on = [
    module.external_dns
  ]
}

module "argocd_app_registration" {
  count  = local.install_argocd ? 1 : 0
  source = "../../src/active-directory/app-registration"

  name     = local.argocd_app_registration_name
  dns_zone = local.dns_zone
}

module "argo_cd" {
  count  = local.install_argocd ? 1 : 0
  source = "../../src/helm/modules/argo-cd"

  cname                       = local.cname_record_argocd
  domain                      = local.dns_zone
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sso_application_id          = module.argocd_app_registration[0].instance.application_id
  administrators_ids          = local.argocd_administrators_ids
  contributors_ids            = local.argocd_contributors_ids
  environment_id              = local.cluster_random_id
  cluster_name                = local.cluster_name
  cluster_ingress_type        = local.cluster_ingress_type
  cluster_certificates_server = local.cert_manager_issuer_server
  cluster_certificates_type   = local.cert_manager_issuer_type

  depends_on = [
    module.argocd_app_registration,
    module.cert_manager,
    module.external_secrets,
    module.external_dns,
    module.ingress_nginx,
  ]
}

module "app_of_apps_infra" {
  count  = local.install_app_of_apps_infra ? 1 : 0
  source = "../../src/helm/modules/app-of-apps-infra"

  environment_id                          = local.cluster_random_id
  environment_cluster_name                = local.cluster_name
  environment_cluster_ingress_type        = local.cluster_ingress_type
  environment_cluster_certificates_type   = local.cert_manager_issuer_type
  environment_cluster_certificates_server = local.cert_manager_issuer_server
  environment_domain                      = local.dns_zone
  target_revision                         = local.argocd_app_of_apps_infra_target_revision

  depends_on = [
    module.argo_cd
  ]
}
