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
