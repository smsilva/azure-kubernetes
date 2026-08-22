locals {
  ingress_nginx_values = templatefile("${path.module}/templates/values.yaml", {
    cname  = var.cname
    domain = var.domain
  })
}

resource "helm_release" "ingress_nginx" {
  chart            = "${path.module}/../../charts/ingress-nginx"
  name             = var.name
  namespace        = var.namespace
  create_namespace = true
  atomic           = true

  values = [
    local.ingress_nginx_values
  ]
}
