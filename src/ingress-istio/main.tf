resource "helm_release" "istio_base" {
  chart            = "${path.module}/../helm/charts/istio-base"
  name             = "istio-base"
  namespace        = "istio-system"
  create_namespace = true
  atomic           = true
}

resource "helm_release" "istio_discovery" {
  chart            = "${path.module}/../helm/charts/istio-discovery"
  name             = "istio-discovery"
  namespace        = "istio-system"
  create_namespace = false
  atomic           = true

  values = [
    file("${path.module}/templates/discovery-mesh-config.yaml")
  ]

  depends_on = [
    helm_release.istio_base
  ]
}

data "template_file" "istio_gateway_service_values" {
  template = file("${path.module}/templates/gateway-service.yaml")
  vars = {
    cname  = var.cname
    domain = var.domain
  }
}

resource "kubernetes_namespace" "istio_ingress" {

  metadata {
    name = "istio-ingress"

    labels = {
      istio-injection = "enabled"
    }
  }

}

resource "helm_release" "istio_gateway" {
  chart            = "${path.module}/../helm/charts/istio-gateway"
  name             = "istio-ingress"
  namespace        = kubernetes_namespace.istio_ingress.metadata[0].name
  create_namespace = false
  atomic           = true

  set {
    name  = "dns.cname"
    value = var.cname
  }

  set {
    name  = "dns.domain"
    value = var.domain
  }

  set {
    name  = "certificate.type"
    value = var.certificate_type
  }

  set {
    name  = "certificate.server"
    value = var.certificate_server
  }

  values = [
    data.template_file.istio_gateway_service_values.rendered
  ]

  depends_on = [
    data.template_file.istio_gateway_service_values,
    helm_release.istio_discovery
  ]
}
