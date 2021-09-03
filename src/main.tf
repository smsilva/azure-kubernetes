data "azurerm_client_config" "default" {
}

resource "random_string" "aks_id" {
  keepers = {
    platform_instance_name = var.platform_instance_name
    cluster_name           = var.cluster_name
    cluster_location       = var.cluster_location
  }

  length      = 3
  min_numeric = 3
  special     = false
  upper       = false
}

resource "azurerm_resource_group" "default" {
  name     = "${var.platform_instance_name}-${var.cluster_name}-${random_string.aks_id.result}"
  location = var.cluster_location
}

resource "azurerm_kubernetes_cluster" "default" {
  name                = azurerm_resource_group.default.name
  dns_prefix          = azurerm_resource_group.default.name
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name

  default_node_pool {
    name                = "default"
    vm_size             = "Standard_D2_v2"
    enable_auto_scaling = true
    node_count          = 1
    min_count           = 1
    max_count           = 5
    max_pods            = 50
    type                = "VirtualMachineScaleSets"
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
      admin_group_object_ids = ["d5075d0a-3704-4ed9-ad62-dc8068c7d0e1"]
    }
  }
}

resource "azurerm_role_assignment" "resource_group" {
  scope                = azurerm_resource_group.default.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_kubernetes_cluster.default.kubelet_identity[0].object_id
}
