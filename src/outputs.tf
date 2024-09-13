output "id" {
  value = module.aks.instance.id
}

output "resource_group_name" {
  value = module.aks.instance.resource_group_name
}

output "resource_group_location" {
  value = azurerm_resource_group.default.location
}

output "network_id" {
  value = module.vnet.instance.id
}

output "application_gateway_id" {
  value = module.application_gateway.instance.id
}

output "application_gateway_public_ip_fqdn" {
  value = module.application_gateway.application_gateway_public_ip_fqdn
}
