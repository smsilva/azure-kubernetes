output "instance" {
  value = azurerm_application_gateway.default
}

output "application_gateway_id" {
  value = azurerm_application_gateway.default.id
}

output "application_gateway_name" {
  value = azurerm_application_gateway.default.name
}

output "application_gateway_location" {
  value = azurerm_application_gateway.default.location
}

output "application_gateway_zones" {
  value = azurerm_application_gateway.default.zones
}

output "application_gateway_public_ip_id" {
  value = azurerm_public_ip.default.id
}

output "application_gateway_public_ip_address" {
  value = azurerm_public_ip.default.ip_address
}

output "application_gateway_public_ip_fqdn" {
  value = azurerm_public_ip.default.fqdn
}

output "public_ip_fqdn" {
  value = azurerm_public_ip.default.fqdn
}
