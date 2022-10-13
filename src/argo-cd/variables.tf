variable "cname" {
  type = string
}

variable "domain" {
  type = string
}

variable "ingress_issuer_name" {
  type        = string
  description = "cert-manager Issuer Name"
  default     = "letsencrypt-nginx-staging"

  validation {
    condition = contains([
      "letsencrypt-production-azure",
      "letsencrypt-staging-azure",
      "letsencrypt-production-nginx",
      "letsencrypt-staging-nginx",
      "letsencrypt-production-istio",
      "letsencrypt-staging-istio",
    ], var.ingress_issuer_name)
    error_message = "This is not an available cert-manager ClusterIssuer."
  }
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
