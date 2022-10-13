variable "cname" {
  type = string
}

variable "domain" {
  type = string
}

variable "sso_application_id" {
  type = string
}

variable "tenant_id" {
  type = string
}

variable "administrators_ids" {
  type = list(string)
}

variable "contributors_ids" {
  type = list(string)
}

variable "environment_id" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "cluster_ingress_type" {
  type = string
}

variable "cluster_certificates_type" {
  type = string
}

variable "cluster_certificates_server" {
  type = string
}
