locals {
  cluster_name             = var.name
  cluster_dns_prefix       = var.dns_prefix != "" ? var.dns_prefix : var.name
  cluster_subnet_id        = var.subnet.id
  resource_group_name      = var.resource_group != "" ? var.resource_group.name : local.cluster_name
  node_resource_group_name = "${local.resource_group_name}-nrg"
}

resource "azurerm_kubernetes_cluster" "default" {
  name                              = local.cluster_name
  dns_prefix                        = local.cluster_dns_prefix
  location                          = data.azurerm_resource_group.default.location
  resource_group_name               = data.azurerm_resource_group.default.name
  node_resource_group               = local.node_resource_group_name
  kubernetes_version                = var.orchestrator_version
  sku_tier                          = var.sku_tier
  role_based_access_control_enabled = true

  default_node_pool {
    name                         = var.node_pool_name
    orchestrator_version         = var.node_pool_kubernetes_version == null ? var.orchestrator_version : var.node_pool_kubernetes_version
    vm_size                      = var.node_pool_vm_size
    min_count                    = var.node_pool_min_count
    max_count                    = var.node_pool_max_count
    max_pods                     = var.node_pool_max_pods
    vnet_subnet_id               = local.cluster_subnet_id
    only_critical_addons_enabled = var.node_pool_only_critical_addons_enabled
    os_disk_type                 = var.node_pool_os_disk_type
    os_disk_size_gb              = var.node_pool_os_disk_size_gb
    enable_auto_scaling          = true
    type                         = "VirtualMachineScaleSets"

    upgrade_settings {
      max_surge = "33%"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    load_balancer_sku = "standard"
    network_plugin    = "azure"
    network_policy    = "azure"
  }

  azure_active_directory_role_based_access_control {
    managed                = true
    azure_rbac_enabled     = true
    admin_group_object_ids = var.administrators_ids
  }
}

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

resource "azurerm_role_assignment" "kubelet_network_contributor_on_subscription" {
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.default.kubelet_identity[0].object_id
  scope                = "/subscriptions/${data.azurerm_client_config.default.subscription_id}"
}

resource "azurerm_role_assignment" "azure_kubernetes_service_cluster_user_role_for_admins" {
  for_each             = toset(var.administrators_ids)
  role_definition_name = "Azure Kubernetes Service Cluster User Role"
  principal_id         = each.value
  scope                = azurerm_kubernetes_cluster.default.id
}
