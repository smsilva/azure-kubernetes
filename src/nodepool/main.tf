resource "azurerm_kubernetes_cluster_node_pool" "default" {
  name                    = var.name
  kubernetes_cluster_id   = var.cluster.id
  auto_scaling_enabled    = true
  vm_size                 = var.vm_size
  min_count               = var.min_count
  max_count               = var.max_count
  max_pods                = var.max_pods
  orchestrator_version    = var.orchestrator_version
  fips_enabled            = false
  node_public_ip_enabled  = false
  host_encryption_enabled = false
  kubelet_disk_type       = "OS"
  os_sku                  = "Ubuntu"
  os_disk_size_gb         = var.os_disk_size_gb
  zones                   = var.zones
  node_taints             = var.taints
  node_labels             = var.labels
  tags                    = var.tags
  vnet_subnet_id          = var.subnet_id
}
