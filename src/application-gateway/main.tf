resource "azurerm_public_ip" "app_gw" {
  name                = local.public_ip_name
  resource_group_name = var.resource_group.name
  location            = var.resource_group.location
  sku                 = var.public_ip_sku
  allocation_method   = var.public_ip_allocation_method
  domain_name_label   = var.public_ip_domain_name_label != null ? var.public_ip_domain_name_label : local.public_ip_name
  tags                = local.tags
}

resource "azurerm_application_gateway" "app_gw" {
  name                = local.application_gateway_name
  resource_group_name = var.resource_group.name
  location            = var.resource_group.location
  zones               = var.zones
  enable_http2        = var.enable_http2
  firewall_policy_id  = var.firewall_policy_id
  tags                = local.tags

  sku {
    name     = var.sku_name
    tier     = var.sku_tier
    capacity = var.autoscale_configuration == null ? var.sku_capacity : null
  }

  dynamic "autoscale_configuration" {
    for_each = var.autoscale_configuration != null ? { config = var.autoscale_configuration } : {}
    content {
      min_capacity = autoscale_configuration.value.min_capacity
      max_capacity = autoscale_configuration.value.max_capacity
    }
  }

  gateway_ip_configuration {
    name      = var.name
    subnet_id = var.subnet_id
  }

  frontend_port {
    name = local.frontend_port_name
    port = 80
  }

  frontend_port {
    name = "httpsPort"
    port = 443
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.app_gw.id
  }

  dynamic "frontend_ip_configuration" {
    for_each = var.private_ip_address != null ? { config = var.private_ip_address } : {}
    content {
      name                          = local.frontend_ip_configuration_name_private
      private_ip_address_allocation = "static"
      private_ip_address            = var.private_ip_address
      subnet_id                     = var.subnet_id
    }
  }

  backend_address_pool {
    name = local.backend_address_pool_name
  }

  backend_http_settings {
    name                  = local.http_setting_name
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 30
  }

  http_listener {
    name                           = local.listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = local.request_routing_rule_name
    rule_type                  = "Basic"
    http_listener_name         = local.listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
    priority                   = 1
  }

  lifecycle {
    ignore_changes = [
      backend_address_pool,
      backend_http_settings,
      frontend_port,
      http_listener,
      identity,
      probe,
      redirect_configuration,
      request_routing_rule,
      ssl_certificate,
      tags["ingress-for-aks-cluster-id"],
      tags["last-updated-by-k8s-ingress"],
      tags["managed-by-k8s-ingress"],
      url_path_map
    ]
  }

  depends_on = [
    azurerm_public_ip.app_gw,
    azurerm_log_analytics_workspace.app_gw
  ]
}
