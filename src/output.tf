output "platform_instance_name" {
  value = var.platform_instance_name
}

output "aks_id" {
  value = azurerm_kubernetes_cluster.default.id
}

output "instance" {
  value = azurerm_kubernetes_cluster.default
}

output "aks_identity_principal_id" {
  value = azurerm_kubernetes_cluster.default.identity[0].principal_id
}

output "aks_kubelet_identity_client_id" {
  value = azurerm_kubernetes_cluster.default.kubelet_identity[0].client_id
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
