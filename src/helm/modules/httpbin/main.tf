resource "kubernetes_namespace_v1" "httpbin" {

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
  namespace        = kubernetes_namespace_v1.httpbin.metadata[0].name
  create_namespace = true
  atomic           = false

  set = [
    {
      name  = "dns.cname"
      value = var.cname
    },
    {
      name  = "dns.domain"
      value = var.domain
    }
  ]

}
