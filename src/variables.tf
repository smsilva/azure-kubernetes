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
  default     = [
    "d5075d0a-3704-4ed9-ad62-dc8068c7d0e1",
  ]
}
