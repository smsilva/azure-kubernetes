variable "resource_group" {}

variable "subnet" {}

variable "name" {
  type        = string
  description = "AKS Cluster Name"
  default     = "aks"
}

variable "dns_prefix" {
  type        = string
  description = "AKS Cluster DNS Prefix"
  default     = ""
}

variable "admin_id_list" {
  type        = list(string)
  description = "AKS Admin Groups"
}

variable "orchestrator_version" {
  type        = string
  description = "Kubernetes Version"
}

variable "default_node_pool_name" {
  type        = string
  description = "Default System Node Pool Name (12 alphanumeric characters only)"
  default     = "system"
  validation {
    condition     = length(var.default_node_pool_name) <= 12
    error_message = "The Node Pool Name should be 12 character long."
  }
}

variable "default_node_pool_vm_size" {
  type        = string
  description = "Default Node Pool Virtual Machine Size"
  default     = "Standard_D2_v2"
}

variable "default_node_pool_os_disk_size_gb" {
  type    = string
  default = "100"
}

variable "default_node_pool_node_count" {
  type    = number
  default = 1
}

variable "default_node_pool_min_count" {
  type    = number
  default = 1
}

variable "default_node_pool_max_count" {
  type    = number
  default = 5
}

variable "default_node_pool_max_pods" {
  type    = number
  default = 120
}