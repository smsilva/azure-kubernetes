variable "name" {
  type    = string
  default = "external-dns"
}

variable "namespace" {
  type    = string
  default = "external-dns"
}

variable "domain" {
  type = string
}

variable "tenantId" {
  type = string
}

variable "subscriptionId" {
  type = string
}

variable "resourceGroup" {
  type = string
}
