resource "helm_release" "app_of_apps_infra" {
  chart            = "${path.module}/../helm/charts/app-of-apps-infra"
  name             = var.name
  namespace        = var.namespace
  create_namespace = false
  atomic           = false

  set {
    name  = "environment.id"
    value = var.environment_id
  }

  set {
    name  = "environment.domain"
    value = var.domain
  }

  set {
    name  = "environment.cluster"
    value = var.cluster_name
  }

  set {
    name  = "source.targetRevision"
    value = var.target_revision
  }
}
