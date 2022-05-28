resource "helm_release" "external_dns" {
  count            = var.install_external_dns ? 1 : 0
  chart            = "${path.module}/charts/external-dns"
  name             = "external-dns"
  namespace        = "external-dns"
  create_namespace = true
  atomic           = true

  depends_on = [
    helm_release.external_secrets_config
  ]
}
