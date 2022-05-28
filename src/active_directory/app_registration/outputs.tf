output "instance" {
  value = azuread_application.default
}

output "password" {
  value     = azuread_application_password.default.value
  sensitive = true
}
