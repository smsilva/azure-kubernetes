locals {
  cluster_name             = var.name
  cluster_dns_prefix       = var.name
  cluster_subnet_id        = var.subnet.id
  orchestrator_version     = var.orchestrator_version
  resource_group_name      = var.resource_group != "" ? var.resource_group.name : local.cluster_name
  node_resource_group_name = "${local.resource_group_name}-nrg"
}

resource "azurerm_kubernetes_cluster" "default" {
  name                              = local.cluster_name
  dns_prefix                        = local.cluster_dns_prefix
  location                          = data.azurerm_resource_group.default.location
  resource_group_name               = data.azurerm_resource_group.default.name
  node_resource_group               = local.node_resource_group_name
  kubernetes_version                = local.orchestrator_version
  role_based_access_control_enabled = true

  default_node_pool {
    name                         = var.default_node_pool_name
    orchestrator_version         = local.orchestrator_version
    only_critical_addons_enabled = false # Default Node Pool will be used to Deploy User Pods
    enable_auto_scaling          = true
    vm_size                      = var.default_node_pool_vm_size
    node_count                   = var.default_node_pool_node_count
    min_count                    = var.default_node_pool_min_count
    max_count                    = var.default_node_pool_max_count
    max_pods                     = var.default_node_pool_max_pods
    type                         = "VirtualMachineScaleSets"
    os_disk_type                 = "Managed"
    os_disk_size_gb              = var.default_node_pool_os_disk_size_gb
    vnet_subnet_id               = local.cluster_subnet_id

    upgrade_settings {
      max_surge = "33%"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    load_balancer_sku = "Standard"
    network_plugin    = "azure"
    network_policy    = "azure"
  }

  azure_active_directory_role_based_access_control {
    managed                = true
    azure_rbac_enabled     = true
    admin_group_object_ids = var.admin_id_list
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

resource "azurerm_role_assignment" "identity_network_contributor_on_subscription" {
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.default.identity[0].principal_id
  scope                = "/subscriptions/${data.azurerm_client_config.default.subscription_id}"
}
