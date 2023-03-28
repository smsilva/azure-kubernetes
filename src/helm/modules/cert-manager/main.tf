resource "helm_release" "cert_manager" {
  chart            = "${path.module}/../../helm/charts/cert-manager"
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
  chart            = "${path.module}/../../helm/charts/cert-manager-issuers"
  name             = "cert-manager-issuers"
  namespace        = "cert-manager"
  create_namespace = true
  atomic           = true

  set {
    name  = "fqdn"
    value = var.fqdn
  }

  depends_on = [
    helm_release.cert_manager
  ]
}
