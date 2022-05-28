data "template_file" "nginx_ingress_controller" {
  template = file("${path.module}/templates/ingress-nginx-values.yaml")
  vars = {
    controller_service_annotations_azure_dns_label_name = var.cluster_instance.name
  }
}

resource "helm_release" "nginx_ingress_controller" {
  count            = var.install_nginx_ingress_controller ? 1 : 0
  chart            = "${path.module}/charts/ingress-nginx"
  name             = "ingress-nginx"
  namespace        = "ingress-nginx"
  create_namespace = true
  atomic           = true

  values = [
    data.template_file.nginx_ingress_controller.rendered
  ]
}
