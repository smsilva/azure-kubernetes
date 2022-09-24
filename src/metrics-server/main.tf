resource "helm_release" "metrics-server" {
  chart            = "${path.module}/../helm/charts/metrics-server"
  name             = "metrics-server"
  namespace        = "metrics-server"
  create_namespace = true
  atomic           = true
}
