data "azurerm_client_config" "default" {
}

data "azurerm_resource_group" "default" {
  name = local.resource_group_name
}

data "azurerm_resource_group" "cluster_infrastructure" {
  name = local.node_resource_group_name

  depends_on = [
    azurerm_kubernetes_cluster.default
  ]
}
