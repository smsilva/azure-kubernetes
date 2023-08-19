# this file is in the common directory

data "azurerm_client_config" "current" {}

data "azurerm_subscription" "current" {}

data "azurerm_dns_zone" "default" {
  name                = local.dns_zone
  resource_group_name = local.dns_zone_resource_group_name
}

data "azurerm_key_vault" "default" {
  name                = local.key_vault_name
  resource_group_name = local.key_vault_resource_group_name
}

resource "random_string" "id" {
  length      = 5
  min_lower   = 3
  min_numeric = 2
  lower       = true
  special     = false
}

module "variables" {
  source = "../../src/variables"
  script = "azure"
}

locals {
  project                                  = "wasp"
  domain                                   = "silvios.me"
  arm_subscription_id_first_8_digits       = substr(data.azurerm_client_config.current.subscription_id, 0, 8)
  arm_subscription_name                    = data.azurerm_subscription.current.display_name
  environment                              = replace(local.arm_subscription_name, "${local.project}-", "")
  arm_client_secret                        = module.variables.values.arm_client_secret
  dns_zone                                 = "${local.environment}" == "production" ? "${local.project}.${local.domain}" : "${local.environment}.${local.project}.${local.domain}"
  dns_zone_resource_group_name             = "${local.project}-foundation"
  key_vault_name                           = "${local.project}foundation${local.arm_subscription_id_first_8_digits}"
  key_vault_resource_group_name            = "${local.project}-foundation"
  cname_record_wildcard                    = "*.${random_string.id.result}"
  cname_record_ingress                     = "gateway.${random_string.id.result}"
  cname_record_argocd                      = "argocd.${random_string.id.result}"
  cert_manager_issuer_type                 = "letsencrypt"
  cert_manager_issuer_server               = "staging" # [ staging | production ]
  cert_manager_fqdn                        = "${local.cname_record_ingress}.${local.dns_zone}"
  cluster_random_id                        = random_string.id.result
  cluster_name                             = "${local.project}-${local.environment}-${random_string.id.result}"
  cluster_resource_group_name              = local.cluster_name
  cluster_resource_group_location          = "eastus2"
  cluster_node_pool_name                   = "system1"
  cluster_administrators_ids               = ["d5075d0a-3704-4ed9-ad62-dc8068c7d0e1"] # aks-administrator
  argocd_contributors_ids                  = ["2deb9d06-5807-4107-a5a6-94368f39d79f"] # aks-contributor
  argocd_app_of_apps_infra_target_revision = "development"
  argocd_host_base_name                    = local.cname_record_argocd
  argocd_app_registration_name             = local.cname_record_argocd
  argocd_administrators_ids                = local.cluster_administrators_ids
  external_dns_domain_filter               = "${local.cluster_random_id}.${local.dns_zone}"
  virtual_network_name                     = local.cluster_name
  virtual_network_cidrs                    = ["10.244.0.0/14"]
  virtual_network_subnets = [
    { cidr = "10.246.0.0/16", name = "aks" },
    { cidr = "10.245.0.0/28", name = "application_gateway" },
  ]
}

resource "azurerm_role_assignment" "kubelet_contributor_on_dns_zone" {
  role_definition_name = "DNS Zone Contributor"
  principal_id         = module.aks.kubelet_identity_object_id
  scope                = data.azurerm_dns_zone.default.id
}
