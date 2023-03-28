resource "kubernetes_namespace" "httpbin" {

  metadata {
    name = "httpbin"

    labels = {
      istio-injection = "enabled"
    }
  }

}

resource "helm_release" "httpbin" {
  chart            = "${path.module}/../../charts/httpbin"
  name             = "httpbin"
  namespace        = kubernetes_namespace.httpbin.metadata[0].name
  create_namespace = true
  atomic           = false

  set {
    name  = "dns.cname"
    value = var.cname
  }

  set {
    name  = "dns.domain"
    value = var.domain
  }

}
