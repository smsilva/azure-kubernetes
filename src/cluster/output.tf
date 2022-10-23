output "id" {
  value = azurerm_kubernetes_cluster.default.id
}

output "instance" {
  value = azurerm_kubernetes_cluster.default
}

output "identity_object_id" {
  value = azurerm_kubernetes_cluster.default.identity[0].principal_id
}

output "kubelet_identity_object_id" {
  value = azurerm_kubernetes_cluster.default.kubelet_identity[0].object_id
}

output "kubelet_identity_client_id" {
  value = azurerm_kubernetes_cluster.default.kubelet_identity[0].client_id
}

output "node_resource_group_id" {
  value = azurerm_kubernetes_cluster.default.node_resource_group
}

output "kubeconfig" {
  value     = azurerm_kubernetes_cluster.default.kube_admin_config_raw
  sensitive = true
}
