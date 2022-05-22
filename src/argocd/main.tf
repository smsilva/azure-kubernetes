variable "url" {
  type    = string
  default = "argocd.example.com"
}

variable "install_cert_manager" {
  type    = bool
  default = false
}

resource "helm_release" "cert_manager" {
  count            = var.install_cert_manager ? 1 : 0
  name             = "cert-manager"
  chart            = "${path.module}/charts/cert-manager-v1.7.2.tgz"
  namespace        = "cert-manager"
  create_namespace = true
  atomic           = true

  set {
    name  = "installCRDs"
    value = "true"
  }
}
