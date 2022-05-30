data "template_file" "ingress_nginx" {
  template = file("${path.module}/template-values.yaml")
  vars = {
    controller_service_annotations_azure_dns_label_name = var.cname
  }
}

resource "helm_release" "ingress_nginx" {
  chart            = "${path.module}/../helm/charts/ingress-nginx"
  name             = var.name
  namespace        = var.namespace
  create_namespace = true
  atomic           = true

  values = [
    data.template_file.ingress_nginx.rendered
  ]
}
