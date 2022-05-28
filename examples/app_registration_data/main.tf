data "azuread_client_config" "current" {}

data "azuread_application" "argocd" {
  display_name = "argocd"
}

output "instance" {
  value = data.azuread_application.argocd
}
