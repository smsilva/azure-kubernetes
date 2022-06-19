data "azurerm_client_config" "current" {}

variable "dns_zone" {
  type        = string
  description = "Azure DNS Zone"
  default     = "sandbox.wasp.silvios.me"
}

variable "cluster_name_prefix" {
  type        = string
  description = "Cluster Name Prefix"
  default     = "wasp-"
}

variable "cluster_base_name" {
  type        = string
  description = "Cluster Name"
  default     = "example"
}

variable "cluster_location" {
  type        = string
  description = "Cluster Location"
  default     = "centralus"
}

variable "cluster_version" {
  type        = string
  description = "Cluster Version"
}

variable "cluster_resource_group_name" {
  type        = string
  description = "Cluster Resource Group Name"
  default     = ""
}

variable "cluster_administrators_ids" {
  type        = list(string)
  description = "AKS Administrator Groups"
}

variable "cluster_default_node_pool_name" {
  type        = string
  description = "Default System Node Pool Name (12 alphanumeric characters only)"
  default     = "system"
  validation {
    condition     = length(var.cluster_default_node_pool_name) <= 12
    error_message = "The Node Pool Name should be 12 character long."
  }
}

variable "cluster_default_node_pool_min_count" {
  type    = number
  default = 3
}

variable "cluster_default_node_pool_max_count" {
  type    = number
  default = 5
}

variable "cluster_default_node_pool_max_pods" {
  type    = number
  default = 120
}

variable "key_vault_name" {
  type = string
}

variable "key_vault_resource_group_name" {
  type    = string
  default = "wasp-foundation"
}

variable "virtual_network_cidrs" {
  default = ["10.244.0.0/14"]
}

variable "virtual_network_subnets" {
  default = [
    { cidr = "10.246.0.0/16", name = "aks" },
    { cidr = "10.247.2.0/27", name = "app-gw" }
  ]
}

variable "install_argocd" {
  type    = bool
  default = false
}

variable "install_cert_manager" {
  type    = bool
  default = false
}

variable "install_external_secrets" {
  type    = bool
  default = false
}

variable "install_external_dns" {
  type    = bool
  default = false
}

variable "install_ingress_nginx" {
  type    = bool
  default = false
}

variable "ARM_CLIENT_SECRET" {
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
  type    = string
  default = "letsencrypt-staging-nginx"
}

variable "argocd_prefix" {
  type        = string
  description = "ArgoCD Prefix"
}
