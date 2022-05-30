resource "helm_release" "external_dns" {
  chart            = "${path.module}/../helm/charts/external-dns"
  name             = var.name
  namespace        = var.namespace
  create_namespace = true
  atomic           = true
}
