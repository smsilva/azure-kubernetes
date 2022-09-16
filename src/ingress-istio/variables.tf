variable "name" {
  type    = string
  default = "ingress-istio"
}

variable "namespace" {
  type    = string
  default = "istio-ingress"
}

variable "cname" {
  type = string
}

variable "domain" {
  type = string
}
