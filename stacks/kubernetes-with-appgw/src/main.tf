locals {
  cluster_name                    = var.cluster_name
  cluster_version                 = var.cluster_version
  cluster_admin_group_ids         = var.cluster_admin_group_ids
  cluster_resource_group_name     = var.cluster_resource_group_name != "" ? var.cluster_resource_group_name : local.cluster_name
  cluster_resource_group_location = var.cluster_location
  application_gateway_name        = local.cluster_name
  virtual_network_name            = local.cluster_name
  virtual_network_cidrs           = var.virtual_network_cidrs
  virtual_network_subnets         = var.virtual_network_subnets
}

resource "azurerm_resource_group" "default" {
  name     = local.cluster_resource_group_name
  location = var.cluster_location
}

module "vnet" {
  source = "git@github.com:smsilva/azure-network.git//src/vnet?ref=3.0.6"

  name                = local.virtual_network_name
  cidrs               = local.virtual_network_cidrs
  subnets             = local.virtual_network_subnets
  resource_group_name = azurerm_resource_group.default.name

  depends_on = [
    azurerm_resource_group.default
  ]
}

module "aks" {
  source = "git@github.com:smsilva/azure-kubernetes.git//src?ref=4.5.0"

  name                 = local.cluster_name
  orchestrator_version = local.cluster_version
  admin_id_list        = local.cluster_admin_group_ids
  subnet               = module.vnet.subnets["aks"].instance
  resource_group       = azurerm_resource_group.default

  depends_on = [
    module.vnet
  ]
}

module "appgw" {
  source = "git@github.com:smsilva/azure-application-gateway.git//src?ref=1.4.0"

  name           = local.application_gateway_name
  resource_group = azurerm_resource_group.default
  subnet         = module.vnet.subnets["app-gw"].instance

  depends_on = [
    module.vnet
  ]
}

resource "azurerm_role_assignment" "identity_contributor_on_application_gateway" {
  role_definition_name = "Contributor"
  principal_id         = module.aks.instance.kubelet_identity[0].object_id
  scope                = module.appgw.instance.id

  depends_on = [
    module.aks,
    module.appgw
  ]
}

resource "azurerm_role_assignment" "identity_reader_on_application_gateway_resource_group" {
  role_definition_name = "Reader"
  principal_id         = module.aks.instance.kubelet_identity[0].object_id
  scope                = azurerm_resource_group.default.id

  depends_on = [
    module.aks,
    module.appgw
  ]
}
