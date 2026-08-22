locals {
  values = templatefile("${path.module}/templates/values.yaml", {
    environment_cluster_ingress_type = var.environment_cluster_ingress_type
  })
}

resource "helm_release" "app_of_apps_infra" {
  chart            = "${path.module}/../../charts/app-of-apps-infra"
  name             = var.name
  namespace        = var.namespace
  create_namespace = false
  atomic           = false

  set = [
    {
      name  = "environment.id"
      value = var.environment_id
    },

    {
      name  = "environment.domain"
      value = var.environment_domain
    }

    , {
      name  = "environment.cluster.name"
      value = var.environment_cluster_name
    }

    , {
      name  = "environment.cluster.ingress.type"
      value = var.environment_cluster_ingress_type
    }

    , {
      name  = "environment.cluster.certificates.type"
      value = var.environment_cluster_certificates_type
    }

    , {
      name  = "environment.cluster.certificates.server"
      value = var.environment_cluster_certificates_server
    }

    , {
      name  = "source.targetRevision"
      value = var.target_revision
  }]

  values = [
    local.values,
  ]
}
