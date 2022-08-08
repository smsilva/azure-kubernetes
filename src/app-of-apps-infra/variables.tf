variable "name" {
  type    = string
  default = "app-of-apps-infra"
}

variable "namespace" {
  type    = string
  default = "argocd"
}

variable "cluster_name" {
  type = string
}

variable "domain" {
  type = string
}

variable "environment_id" {
  type = string
}

variable "environment_cluster" {
  type = string
}

variable "target_revision" {
  type        = string
  description = "Git Target Revision"
  default     = "HEAD"
}
