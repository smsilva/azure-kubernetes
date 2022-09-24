locals {
  cluster_random_id                        = random_string.id.result
  cluster_name                             = "wasp-${local.cluster_random_id}"
  cluster_resource_group_name              = local.cluster_name
  cluster_resource_group_location          = "eastus2"
  cluster_version                          = "1.23.8"
  cluster_node_pool_min_count              = 2
  cluster_node_pool_max_count              = 5
  cluster_node_pool_name                   = "system1"
  cluster_administrators_ids               = ["d5075d0a-3704-4ed9-ad62-dc8068c7d0e1"] # aks-administrator
  install_cert_manager                     = true
  install_external_secrets                 = true
  install_external_dns                     = true
  install_ingress_istio                    = true
  install_httpbin                          = true
  install_argocd                           = true
  install_app_of_apps_infra                = true
  dns_zone                                 = "sandbox.wasp.silvios.me"
  cluster_ingress_type                     = "istio"
  cert_manager_issuer_type                 = "letsencrypt"
  cert_manager_issuer_server               = "staging"
  argocd_host_base_name                    = "argocd.${local.cluster_random_id}"
  argocd_app_registration_name             = local.argocd_host_base_name
  argocd_administrators_ids                = local.cluster_administrators_ids
  argocd_contributors_ids                  = ["2deb9d06-5807-4107-a5a6-94368f39d79f"] # aks-contributor
  argocd_app_of_apps_infra_target_revision = "development"
  argocd_ingress_issuer_name               = "${local.cert_manager_issuer_type}-${local.cert_manager_issuer_server}-${local.cluster_ingress_type}"
  key_vault_name                           = "waspfoundation636a465c"
  key_vault_resource_group_name            = "wasp-foundation"
  virtual_network_name                     = local.cluster_name
  virtual_network_cidrs                    = ["10.244.0.0/14"]
  virtual_network_subnets                  = [{ cidr = "10.246.0.0/16", name = "aks" }]
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

module "argocd_app_registration" {
  source = "../../src/active-directory/app-registration"

  name     = local.argocd_app_registration_name
  dns_zone = local.dns_zone
}

module "cert_manager" {
  count  = local.install_cert_manager ? 1 : 0
  source = "../../src/cert-manager"

  depends_on = [
    module.aks
  ]
}

module "external_secrets" {
  count  = local.install_external_secrets ? 1 : 0
  source = "../../src/external-secrets"

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
  source = "../../src/external-dns"

  depends_on = [
    module.external_secrets
  ]
}

module "ingress_istio" {
  count  = local.install_ingress_istio ? 1 : 0
  source = "../../src/ingress-istio"

  cname              = local.cluster_random_id
  domain             = local.dns_zone
  certificate_type   = local.cert_manager_issuer_type
  certificate_server = local.cert_manager_issuer_server

  depends_on = [
    module.external_dns,
    module.cert_manager
  ]
}

module "httpbin" {
  count  = local.install_httpbin ? 1 : 0
  source = "../../src/httpbin"

  cname  = local.cluster_random_id
  domain = local.dns_zone

  depends_on = [
    module.ingress_istio
  ]
}

module "argo_cd" {
  count  = local.install_argocd ? 1 : 0
  source = "../../src/argo-cd"

  cname               = local.argocd_host_base_name
  domain              = local.dns_zone
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sso_application_id  = module.argocd_app_registration.instance.application_id
  administrators_ids  = local.argocd_administrators_ids
  contributors_ids    = local.argocd_contributors_ids
  ingress_issuer_name = local.argocd_ingress_issuer_name

  depends_on = [
    module.argocd_app_registration,
    module.cert_manager,
    module.external_dns,
    module.external_secrets,
    module.ingress_istio,
  ]
}

module "app_of_apps_infra" {
  count  = local.install_app_of_apps_infra ? 1 : 0
  source = "../../src/app-of-apps-infra"

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
