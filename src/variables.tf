variable "cluster_name" {
  type        = string
  description = "AKS Cluster Name"
  default     = "aks"
}

variable "cluster_location" {
  type        = string
  description = "AKS Cluster Location"
  default     = "eastus2"
}

variable "cluster_admin_group_ids" {
  type        = list(string)
  description = "AKS Admin Groups"
}

variable "cluster_version" {
  type        = string
  description = "AKS Version"
}

variable "cluster_subnet_id" {
  type        = string
  description = "AKS Node Pool Subnet ID"
}

variable "default_node_pool_name" {
  type        = string
  description = "Default System Node Pool Name (12 alphanumeric characters only)"
  default     = "system"
}

variable "resource_group_name" {
  type    = string
  default = ""
}
