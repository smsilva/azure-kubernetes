resource "azurerm_user_assigned_identity" "default" {
  name                = var.name
  resource_group_name = var.resource_group.name
  location            = var.resource_group.location
}

resource "azurerm_federated_identity_credential" "default" {
  name                      = var.name
  user_assigned_identity_id = azurerm_user_assigned_identity.default.id
  audience                  = ["api://AzureADTokenExchange"]
  issuer                    = var.oidc_issuer_url
  subject                   = "system:serviceaccount:${var.namespace}:${var.service_account_name}"
}