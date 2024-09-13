variable "administrators_ids" {
  description = "The list of administrator ids"
  type        = list(string)
}

variable "kubernetes_version" {
  description = "The version of the cluster"
  default     = "1.28.12"
}

variable "name" {
  description = "The name of the cluster"
}

variable "location" {
  description = "The location of the resource group"
  default     = "eastus2"
}

variable "resource_group_name" {
  description = "The name of the resource group"
  default     = ""
}

variable "ingress_type" {
  description = "Ingress Type (nginx | azure | istio)"
  type        = string
  default     = "azure"
}

variable "virtual_network_name" {
  description = "Virtual Network Name"
  type        = string
  default     = ""
}

variable "virtual_network_cidrs" {
  description = "Virtual Network CIDRs"
  type        = list(string)
  default     = ["10.244.0.0/14"]
}

variable "virtual_network_subnets" {
  description = "Virtual Network Subnets"
  type = list(object({
    cidr = string
    name = string
  }))
  default = [
    { cidr = "10.246.0.0/16", name = "aks" },
    { cidr = "10.245.0.0/28", name = "application_gateway" },
  ]
}

variable "node_pool_name" {
  description = "The name of the node pool"
  default     = "system1"
}

variable "node_pool_min_count" {
  description = "The minimum number of nodes in the node pool"
  default     = 1
}

variable "node_pool_max_count" {
  description = "The maximum number of nodes in the node pool"
  default     = 5
}

variable "subnet_name" {
  description = "The name of the subnet"
  default     = "aks"
}

variable "application_gateway_subnet_name" {
  description = "The name of the application gateway subnet"
  default     = "application_gateway"
}

variable "install_cert_manager" {
  type        = bool
  description = "Install Cert Manager"
  default     = false
}

variable "install_external_secrets" {
  type        = bool
  description = "Install External Secrets"
  default     = false
}

variable "key_vault_name" {
  description = "The name of the key vault"
}

variable "key_vault_resource_group_name" {
  description = "The name of the resource group where the key vault is located"
}
