data "template_file" "ingress_azure" {
  template = file("${path.module}/templates/values.yaml")
  vars = {
    arm_auth_identity_resource_id = var.identity_resource_id
    arm_auth_identity_client_id   = var.identity_client_id
    app_gw_subscription_id        = var.subscription_id
    app_gw_resource_group         = var.application_gateway.resource_group_name
    app_gw_name                   = var.application_gateway.name
  }
}

resource "helm_release" "aad_pod_identity" {
  chart            = "${path.module}/../helm/charts/aad-pod-identity"
  name             = "aad-pod-identity"
  namespace        = "kube-system"
  create_namespace = false
  atomic           = true
}

resource "helm_release" "ingress_azure" {
  chart            = "${path.module}/../helm/charts/ingress-azure"
  name             = "ingress-azure"
  namespace        = "ingress-azure"
  create_namespace = true
  atomic           = true

  values = [
    data.template_file.ingress_azure.rendered
  ]

  depends_on = [
    helm_release.aad_pod_identity
  ]
}
