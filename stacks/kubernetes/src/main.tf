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
  source = "git@github.com:smsilva/azure-network.git//src/vnet?ref=3.0.5"

  name                = local.virtual_network_name
  cidrs               = local.virtual_network_cidrs
  subnets             = local.virtual_network_subnets
  resource_group_name = azurerm_resource_group.default.name

  depends_on = [
    azurerm_resource_group.default
  ]
}

module "aks" {
  source = "git@github.com:smsilva/azure-kubernetes.git//src?ref=3.13.0"

  name            = local.cluster_name
  version         = local.cluster_version
  subnet          = module.vnet.subnets["aks"].instance
  admin_group_ids = local.cluster_admin_group_ids
  resource_group  = azurerm_resource_group.default

  depends_on = [
    module.vnet
  ]
}
