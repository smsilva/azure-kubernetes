locals {
  cluster_random_id               = random_string.id.result
  cluster_base_name               = "example-${local.cluster_random_id}"
  cluster_name                    = "wasp-${local.cluster_base_name}"
  cluster_resource_group_name     = local.cluster_name
  cluster_resource_group_location = "eastus2"
  cluster_version                 = "1.21.9"
  node_pool_kubernetes_version    = local.cluster_version
  cluster_node_pool_min_count     = 3
  cluster_node_pool_max_count     = 5
  cluster_node_pool_name          = "system01"
  cluster_administrators_ids      = ["d5075d0a-3704-4ed9-ad62-dc8068c7d0e1"] # aks-administrator
  virtual_network_name            = local.cluster_name
  virtual_network_cidrs           = ["10.244.0.0/14"]
  virtual_network_subnets         = [{ cidr = "10.246.0.0/16", name = "aks" }]
  install_cert_manager            = true
  install_external_secrets        = true
  install_external_dns            = true
  install_ingress_nginx           = true
  install_argocd                  = true
  dns_zone                        = "sandbox.wasp.silvios.me"
  argocd_host_base_name           = "argocd-${local.cluster_base_name}"
  argocd_app_registration_name    = local.argocd_host_base_name
  argocd_administrators_ids       = local.cluster_administrators_ids
  argocd_contributors_ids         = ["2deb9d06-5807-4107-a5a6-94368f39d79f"] # aks-contributor
  key_vault_name                  = "waspfoundation636a465c"
  key_vault_resource_group_name   = "wasp-foundation"
}

resource "azurerm_resource_group" "default" {
  name     = local.cluster_resource_group_name
  location = local.cluster_resource_group_location
}

module "aks" {
  source = "../../src/cluster"

  name                         = local.cluster_name
  orchestrator_version         = local.cluster_version
  administrators_ids           = local.cluster_administrators_ids
  node_pool_name               = local.cluster_node_pool_name
  node_pool_min_count          = local.cluster_node_pool_min_count
  node_pool_max_count          = local.cluster_node_pool_max_count
  node_pool_kubernetes_version = local.node_pool_kubernetes_version
  resource_group               = azurerm_resource_group.default
  subnet                       = module.vnet.subnets["aks"].instance

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
  client_secret  = var.arm_client_secret
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

module "ingress_nginx" {
  count  = local.install_ingress_nginx ? 1 : 0
  source = "../../src/ingress-nginx"

  cname = module.aks.instance.name

  depends_on = [
    module.aks
  ]
}

module "argo_cd" {
  count  = local.install_argocd ? 1 : 0
  source = "../../src/argo-cd"

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
