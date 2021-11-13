variable "name" {
  type        = string
  description = "Cluster Name"
  default     = "wasp-aks"
}

variable "location" {
  type        = string
  description = "Cluster Location"
  default     = "centralus"
}

variable "resource_group_name" {
  type        = string
  description = "Resource Group Name"
}
