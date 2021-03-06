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

variable "target_revision" {
  type        = string
  description = "Git Target Revision"
  default     = "HEAD"
}
