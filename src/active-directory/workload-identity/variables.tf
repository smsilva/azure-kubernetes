variable "name" {
  type        = string
  description = "User Assigned Managed Identity name"
}

variable "resource_group" {
  type        = any
  description = "Resource Group object (name and location) where the identity is created"
}

variable "oidc_issuer_url" {
  type        = string
  description = "AKS cluster OIDC issuer URL used to federate the identity"
}

variable "namespace" {
  type        = string
  description = "Kubernetes namespace of the federated Service Account"
}

variable "service_account_name" {
  type        = string
  description = "Kubernetes Service Account name to federate with the identity"
}