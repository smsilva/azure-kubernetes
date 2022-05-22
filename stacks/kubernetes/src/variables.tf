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
  type = string
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

variable "argocd_url" {
  type = string
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
