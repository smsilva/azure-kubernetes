output "instance" {
  value = azurerm_application_gateway.app_gw
}

output "application_gateway_id" {
  value = azurerm_application_gateway.app_gw.id
}

output "application_gateway_name" {
  value = azurerm_application_gateway.app_gw.name
}

output "application_gateway_location" {
  value = azurerm_application_gateway.app_gw.location
}

output "application_gateway_zones" {
  value = azurerm_application_gateway.app_gw.zones
}

output "application_gateway_public_ip_id" {
  value = azurerm_public_ip.app_gw.id
}

output "application_gateway_public_ip_address" {
  value = azurerm_public_ip.app_gw.ip_address
}

output "application_gateway_public_ip_fqdn" {
  value = azurerm_public_ip.app_gw.fqdn
}
