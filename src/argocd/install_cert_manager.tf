resource "helm_release" "cert_manager" {
  count            = var.install_cert_manager ? 1 : 0
  chart            = "${path.module}/charts/cert-manager-v1.7.2.tgz"
  name             = "cert-manager"
  namespace        = "cert-manager"
  create_namespace = true
  atomic           = true

  set {
    name  = "installCRDs"
    value = "true"
  }
}

resource "helm_release" "cert_manager_issuers" {
  count            = var.install_cert_manager ? 1 : 0
  chart            = "${path.module}/charts/cert-manager-issuers"
  name             = "cert-manager-issuers"
  namespace        = "cert-manager"
  create_namespace = true
  atomic           = true

  depends_on = [
    helm_release.cert_manager
  ]
}
