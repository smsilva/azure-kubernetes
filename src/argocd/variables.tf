data "azurerm_client_config" "current" {}

variable "cluster_instance" {
  type = object({
    name = string
  })
}

variable "domain" {
  type        = string
  description = "Base Domain"
}

variable "argocd_host" {
  type        = string
  description = "ArgoCD host"
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

variable "argocd_administrators_ids" {
  type = list(string)
}

variable "argocd_contributors_ids" {
  type = list(string)
}

variable "argocd_ingress_issuer_name" {
  type        = string
  description = "cert-manager Issuer Name"
  default     = "letsencrypt-nginx-staging"

  validation {
    condition = contains([
      "letsencrypt-application-gateway-production",
      "letsencrypt-application-gateway-staging",
      "letsencrypt-nginx-production",
      "letsencrypt-nginx-staging",
    ], var.argocd_ingress_issuer_name)
    error_message = "This is not a cert-manager ClusterIssuer available."
  }
}
