data "template_file" "ingress_nginx" {
  template = file("${path.module}/templates/values.yaml")
  vars = {
    cname  = var.cname
    domain = var.domain
  }
}

resource "helm_release" "ingress_nginx" {
  chart            = "${path.module}/../../charts/ingress-nginx"
  name             = var.name
  namespace        = var.namespace
  create_namespace = true
  atomic           = true

  values = [
    data.template_file.ingress_nginx.rendered
  ]
}
