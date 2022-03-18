locals {
  cluster_location               = "eastus2"
  cluster_name                   = "wasp-aks-${random_string.id.result}"
  cluster_version                = "1.21.7"
  cluster_resource_group_name    = local.cluster_name
  cluster_admin_id_list          = ["d5075d0a-3704-4ed9-ad62-dc8068c7d0e1"] # aks-administrator
  cluster_default_node_pool_name = "npsys01" # 12 Alphanumeric characters
}

resource "azurerm_resource_group" "default" {
  name     = local.cluster_resource_group_name
  location = local.cluster_location
}

module "aks" {
  source = "../../src"

  name                   = local.cluster_name
  location               = local.cluster_location
  orchestrator_version   = local.cluster_version
  admin_id_list          = local.cluster_admin_id_list
  default_node_pool_name = local.cluster_default_node_pool_name
  resource_group         = azurerm_resource_group.default
  subnet                 = module.vnet.subnets["aks"].instance

  depends_on = [
    azurerm_resource_group.default,
    module.vnet
  ]
}
