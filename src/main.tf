data "azurerm_client_config" "current" {}

data "azurerm_subscription" "current" {}

data "azurerm_key_vault" "default" {
  name                = var.key_vault_name
  resource_group_name = var.key_vault_resource_group_name
}

module "variables" {
  source = "./variables"
  script = "azure"
}

locals {
  cluster_name                       = var.name
  cluster_version                    = var.kubernetes_version
  cluster_administrators_ids         = var.administrators_ids
  cluster_node_pool_name             = var.node_pool_name
  cluster_node_pool_min_count        = var.node_pool_min_count
  cluster_node_pool_max_count        = var.node_pool_max_count
  cluster_virtual_network_name       = var.virtual_network_name != "" ? var.virtual_network_name : local.cluster_name
  cluster_resource_group_name        = var.resource_group_name != "" ? var.resource_group_name : local.cluster_name
  cluster_resource_group_location    = var.location
  arm_client_secret                  = module.variables.arm_client_secret
  arm_subscription_id_first_8_digits = substr(data.azurerm_client_config.current.subscription_id, 0, 8)
  key_vault_name                     = "foundation${local.arm_subscription_id_first_8_digits}"
}

resource "azurerm_resource_group" "default" {
  name     = local.cluster_resource_group_name
  location = local.cluster_resource_group_location
}

module "vnet" {
  source = "git@github.com:smsilva/azure-network.git//src/vnet?ref=3.0.6"

  name                = local.cluster_virtual_network_name
  cidrs               = var.virtual_network_cidrs
  subnets             = var.virtual_network_subnets
  resource_group_name = local.cluster_resource_group_name

  depends_on = [
    azurerm_resource_group.default
  ]
}

module "aks" {
  source = "./cluster"

  name                                   = local.cluster_name
  orchestrator_version                   = local.cluster_version
  administrators_ids                     = local.cluster_administrators_ids
  node_pool_name                         = local.cluster_node_pool_name
  node_pool_min_count                    = local.cluster_node_pool_min_count
  node_pool_max_count                    = local.cluster_node_pool_max_count
  resource_group                         = azurerm_resource_group.default
  subnet                                 = module.vnet.subnets[var.subnet_name].instance
  node_pool_only_critical_addons_enabled = false

  depends_on = [
    module.vnet
  ]
}

module "application_gateway" {
  source = "./application-gateway"

  name           = local.cluster_name
  subnet_id      = module.vnet.subnets[var.application_gateway_subnet_name].instance.id
  resource_group = azurerm_resource_group.default

  depends_on = [
    module.vnet
  ]
}

module "cert_manager" {
  count  = var.install_cert_manager ? 1 : 0
  source = "./helm/modules/cert-manager"

  fqdn = module.application_gateway.public_ip_fqdn

  depends_on = [
    module.aks
  ]
}

module "external_secrets" {
  count  = var.install_external_secrets ? 1 : 0
  source = "./helm/modules/external-secrets"

  tenant_id      = data.azurerm_client_config.current.tenant_id
  client_id      = data.azurerm_client_config.current.client_id
  client_secret  = local.arm_client_secret
  key_vault_name = data.azurerm_key_vault.default.name

  depends_on = [
    module.aks
  ]
}
