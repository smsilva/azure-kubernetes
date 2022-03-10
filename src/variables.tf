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

variable "default_node_pool_vm_size" {
  default = "Standard_D2_v2"
}

variable "default_node_pool_count" {
  default = 1
}

variable "default_node_pool_min_count" {
  default = 1
}

variable "default_node_pool_max_count" {
  default = 5
}

variable "resource_group_name" {
  type    = string
  default = ""
}
