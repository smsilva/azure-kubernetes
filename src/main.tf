locals {
  cluster_name             = var.cluster_name
  cluster_dns_prefix       = var.cluster_name
  resource_group_name      = var.resource_group_name != "" ? var.resource_group_name : var.cluster_name
  node_resource_group_name = "${local.resource_group_name}-nrg"
}

resource "azurerm_kubernetes_cluster" "default" {
  name                = local.cluster_name
  dns_prefix          = local.cluster_dns_prefix
  location            = data.azurerm_resource_group.default.location
  resource_group_name = data.azurerm_resource_group.default.name
  node_resource_group = local.node_resource_group_name
  kubernetes_version  = var.cluster_version

  default_node_pool {
    name                         = var.default_node_pool_name
    orchestrator_version         = var.cluster_version
    only_critical_addons_enabled = false # Default Node Pool will be used to Deploy User Pods
    enable_auto_scaling          = true
    vm_size                      = var.default_node_pool_vm_size
    node_count                   = var.default_node_pool_count
    min_count                    = var.default_node_pool_min_count
    max_count                    = var.default_node_pool_max_count
    max_pods                     = 120
    type                         = "VirtualMachineScaleSets"
    os_disk_type                 = "Managed"
    os_disk_size_gb              = "100"
    vnet_subnet_id               = var.cluster_subnet_id

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

  role_based_access_control {
    enabled = true

    azure_active_directory {
      managed                = true
      admin_group_object_ids = var.cluster_admin_group_ids
    }
  }
}

resource "azurerm_role_assignment" "resource_group" {
  scope                = data.azurerm_resource_group.default.id
  principal_id         = azurerm_kubernetes_cluster.default.kubelet_identity[0].object_id
  role_definition_name = "Contributor"
}

# Make the Kubelet able to make changes on Cluster Infrastructure Resource Group
# This is needed when using Azure Application Gateway + Azure Active Directory Pod Identity https://github.com/Azure/aad-pod-identity
resource "azurerm_role_assignment" "kubelet_contributor_on_cluster_infrastructure_resource_group" {
  scope                = data.azurerm_resource_group.cluster_infrastructure.id
  principal_id         = azurerm_kubernetes_cluster.default.kubelet_identity[0].object_id
  role_definition_name = "Contributor"
}
