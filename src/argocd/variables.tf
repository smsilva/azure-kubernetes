data "azurerm_client_config" "current" {}

variable "url" {
  type    = string
  default = "argocd.example.com"
}

variable "argocd_sso_application_id" {
  type        = string
  description = "Active Directory App Registration: Application (client) ID"
  default     = "5b59d3e0-04f4-4be4-aff4-b159a8ed4b46" # argocd
}

variable "install_cert_manager" {
  type    = bool
  default = false
}

variable "install_external_secrets" {
  type    = bool
  default = false
}

variable "install_nginx_ingress_controller" {
  type    = bool
  default = false
}

variable "install_argocd" {
  type    = bool
  default = false
}

variable "install_external_dns" {
  type    = bool
  default = false
}

variable "armKeyVaultName" {
  type = string
}

variable "armClientSecret" {
  type      = string
  sensitive = true
}

variable "argocd_rbac_group_admin" {
  type = string
}

variable "argocd_rbac_group_contributor" {
  type = string
}
