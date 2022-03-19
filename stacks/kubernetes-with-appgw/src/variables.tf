variable "cluster_id" {
  type        = string
  description = "Will be used to store Cluster Secrets"
  default     = "eus2-a"
}

variable "cluster_name" {
  type        = string
  description = "Cluster Name"
  default     = "wasp-aks"
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

variable "cluster_admin_group_ids" {
  type        = list(string)
  description = "AKS Admin Groups"
}

variable "keyvault_name" {
  type = string
}

variable "keyvault_resource_group_name" {
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
