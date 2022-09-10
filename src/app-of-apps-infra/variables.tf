variable "name" {
  type    = string
  default = "app-of-apps-infra"
}

variable "namespace" {
  type    = string
  default = "argocd"
}

variable "environment_id" {
  type = string
}

variable "environment_domain" {
  type = string
}

variable "environment_cluster_name" {
  type = string
}

variable "environment_cluster_ingress_type" {
  type = string
}

variable "target_revision" {
  type        = string
  description = "Git Target Revision"
  default     = "HEAD"
}
