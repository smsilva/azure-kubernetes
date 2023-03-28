data "template_file" "values" {
  template = file("${path.module}/templates/values.yaml")
  vars = {
    environment_cluster_ingress_type = var.environment_cluster_ingress_type
  }
}

resource "helm_release" "app_of_apps_infra" {
  chart            = "${path.module}/../../charts/app-of-apps-infra"
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
    value = var.environment_domain
  }

  set {
    name  = "environment.cluster.name"
    value = var.environment_cluster_name
  }

  set {
    name  = "environment.cluster.ingress.type"
    value = var.environment_cluster_ingress_type
  }

  set {
    name  = "environment.cluster.certificates.type"
    value = var.environment_cluster_certificates_type
  }

  set {
    name  = "environment.cluster.certificates.server"
    value = var.environment_cluster_certificates_server
  }

  set {
    name  = "source.targetRevision"
    value = var.target_revision
  }

  values = [
    data.template_file.values.rendered,
  ]
}
