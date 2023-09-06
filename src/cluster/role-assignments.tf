resource "azurerm_role_assignment" "kubelet_contributor_on_cluster_resource_group" {
  role_definition_name = "Contributor"
  principal_id         = azurerm_kubernetes_cluster.default.kubelet_identity[0].object_id
  scope                = data.azurerm_resource_group.default.id
}

resource "azurerm_role_assignment" "kubelet_contributor_on_cluster_infrastructure_resource_group" {
  role_definition_name = "Contributor"
  principal_id         = azurerm_kubernetes_cluster.default.kubelet_identity[0].object_id
  scope                = data.azurerm_resource_group.cluster_infrastructure.id
}

resource "azurerm_role_assignment" "kubelet_network_contributor_on_aks_subnet" {
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.default.kubelet_identity[0].object_id
  scope                = local.cluster_subnet_id
}

resource "azurerm_role_assignment" "azure_kubernetes_service_cluster_user_role_for_admins" {
  for_each             = toset(var.administrators_ids)
  role_definition_name = "Azure Kubernetes Service Cluster User Role"
  principal_id         = each.value
  scope                = azurerm_kubernetes_cluster.default.id
}
