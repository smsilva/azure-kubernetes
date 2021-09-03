output "aks_id" {
  value = azurerm_kubernetes_cluster.default.id
}

output "aks_identity_id" {
  value = azurerm_kubernetes_cluster.default.identity[0]
}

output "aks_kubelet_identity_id" {
  value = azurerm_kubernetes_cluster.default.kubelet_identity[0]
}

output "aks_resource_group_id" {
  value = azurerm_resource_group.default.id
}

output "aks_node_resource_group_id" {
  value = azurerm_kubernetes_cluster.default.node_resource_group
}

output "aks_kubeconfig" {
  value     = azurerm_kubernetes_cluster.default.kube_admin_config_raw
  sensitive = true
}
