resource "azurerm_log_analytics_workspace" "default" {
  name                = local.application_gateway_name
  location            = var.resource_group.location
  resource_group_name = var.resource_group.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = local.tags
}

resource "azurerm_monitor_diagnostic_setting" "default" {
  name                       = local.application_gateway_name
  target_resource_id         = azurerm_application_gateway.default.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.default.id

  dynamic "enabled_log" {
    for_each = [
      "ApplicationGatewayAccessLog",
      "ApplicationGatewayPerformanceLog",
      "ApplicationGatewayFirewallLog"
    ]

    content {
      category = enabled_log.value

      retention_policy {
        enabled = false
      }
    }
  }

  metric {
    category = "AllMetrics"

    retention_policy {
      enabled = false
    }
  }

  depends_on = [
    azurerm_application_gateway.default,
    azurerm_log_analytics_workspace.default
  ]
}
