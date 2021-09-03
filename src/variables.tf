variable "platform_instance_name" {
  description = "Platform Instance Name"
  type        = string
}

variable "cluster_name" {
  description = "AKS Cluster Name"
  type        = string
}

variable "cluster_location" {
  description = "AKS Cluster Location"
  type        = string
}

variable "admin_group_object_ids" {
  description = "AKS Admin Groups"
  type        = list(string)
}

variable "cluster_version" {
  description = "AKS Version"
  type        = string
}
