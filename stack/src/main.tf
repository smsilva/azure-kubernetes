locals {
  cluster_name            = var.cluster_name
  virtual_network_name    = local.cluster_name
  virtual_network_cidrs   = var.virtual_network_cidrs
  virtual_network_subnets = var.virtual_network_subnets
  resource_group_name     = var.resource_group_name != "" ? var.resource_group_name : local.cluster_name
  cluster_admin_group_ids = var.cluster_admin_group_ids
}

resource "azurerm_resource_group" "default" {
  name     = local.resource_group_name
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
  source = "git@github.com:smsilva/azure-kubernetes.git//src?ref=3.9.0"

  cluster_name            = local.cluster_name
  cluster_location        = azurerm_resource_group.default.location
  cluster_version         = var.cluster_version
  cluster_subnet_id       = module.vnet.subnets["aks"].instance.id
  cluster_admin_group_ids = local.cluster_admin_group_ids
  resource_group_name     = azurerm_resource_group.default.name

  depends_on = [
    azurerm_resource_group.default
  ]
}
