output "aks_id" {
  value = azurerm_kubernetes_cluster.default.id
}

output "instance" {
  value = azurerm_kubernetes_cluster.default
}

output "identity" {
  value = azurerm_kubernetes_cluster.default.identity[0]
}

output "aks_identity_principal_id" {
  value = azurerm_kubernetes_cluster.default.identity[0].principal_id
}

output "aks_kubelet_identity_client_id" {
  value = azurerm_kubernetes_cluster.default.kubelet_identity[0].client_id
}

output "aks_node_resource_group_id" {
  value = azurerm_kubernetes_cluster.default.node_resource_group
}

output "aks_kubeconfig" {
  value     = azurerm_kubernetes_cluster.default.kube_admin_config_raw
  sensitive = true
}
