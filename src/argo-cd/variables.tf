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
      "letsencrypt-application-gateway-production",
      "letsencrypt-application-gateway-staging",
      "letsencrypt-nginx-production",
      "letsencrypt-nginx-staging",
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
