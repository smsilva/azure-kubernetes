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
  name     = "${var.platform_instance_name}-aks"
  location = var.cluster_location
}

resource "azurerm_kubernetes_cluster" "default" {
  name                = azurerm_resource_group.default.name
  dns_prefix          = azurerm_resource_group.default.name
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name

  default_node_pool {
    name                         = "systempool"
    orchestrator_version         = var.cluster_version
    only_critical_addons_enabled = true
    enable_auto_scaling          = true
    vm_size                      = "Standard_D2_v2"
    node_count                   = 1
    min_count                    = 1
    max_count                    = 5
    max_pods                     = 100
    type                         = "VirtualMachineScaleSets"
    os_disk_type                 = "Managed"
    os_disk_size_gb              = "100"

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
      admin_group_object_ids = var.admin_group_object_ids
    }
  }

  addon_profile {
    oms_agent {
      enabled = false
    }

    aci_connector_linux {
      enabled = false
    }

    azure_policy {
      enabled = false
    }

    http_application_routing {
      enabled = false
    }

    kube_dashboard {
      enabled = false
    }
  }
}

resource "azurerm_role_assignment" "resource_group" {
  scope                = azurerm_resource_group.default.id
  principal_id         = azurerm_kubernetes_cluster.default.kubelet_identity[0].object_id
  role_definition_name = "Contributor"
}
