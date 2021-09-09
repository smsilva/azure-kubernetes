variable "platform_instance_name" {
  type        = string
  description = "Platform Instance Name"
}

variable "cluster_name" {
  type        = string
  description = "AKS Cluster Name"
  default     = "aks"
}

variable "cluster_location" {
  type        = string
  description = "AKS Cluster Location"
  default     = "centralus"
}

variable "admin_group_object_ids" {
  type        = list(string)
  description = "AKS Admin Groups"
}

variable "cluster_version" {
  type        = string
  description = "AKS Version"
}

variable "subnet_id" {
  type        = string
  description = "AKS Node Pool Subnet ID"
}
