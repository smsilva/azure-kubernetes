resource "random_string" "id" {
  length      = 3
  min_lower   = 1
  min_numeric = 2
  lower       = true
  special     = false
}

locals {
  azuread_application_name = "argocd-example-${random_string.id.result}"
  azure_dns_zone           = "sandbox.wasp.silvios.me"
}

module "argocd_app_registration" {
  source = "../../src/active_directory/app_registration"

  name     = local.azuread_application_name
  dns_zone = local.azure_dns_zone
}

output "password_id" {
  value     = module.argocd_app_registration.instance.id
  sensitive = false
}

output "password_value" {
  value     = module.argocd_app_registration.password
  sensitive = true
}
