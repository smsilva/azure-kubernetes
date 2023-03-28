variable "name" {
  type    = string
  default = "ingress-nginx"
}

variable "namespace" {
  type    = string
  default = "ingress-nginx"
}

variable "cname" {
  type = string
}

variable "domain" {
  type = string
}
