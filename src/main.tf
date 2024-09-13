locals {
  cluster_name                 = var.name
  cluster_version              = var.kubernetes_version
  cluster_administrators_ids   = var.administrators_ids
  cluster_node_pool_name       = var.node_pool_name
  cluster_node_pool_min_count  = var.node_pool_min_count
  cluster_node_pool_max_count  = var.node_pool_max_count
  cluster_virtual_network_name = var.virtual_network_name != "" ? var.virtual_network_name : local.cluster_name
}

resource "azurerm_resource_group" "default" {
  name     = var.resource_group_name
  location = var.resource_group_location
}

module "vnet" {
  source = "git@github.com:smsilva/azure-network.git//src/vnet?ref=3.0.6"

  name                = local.cluster_virtual_network_name
  cidrs               = var.virtual_network_cidrs
  subnets             = var.virtual_network_subnets
  resource_group_name = azurerm_resource_group.default.name

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
