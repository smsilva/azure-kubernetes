data "template_file" "ingress_azure" {
  template = file("${path.module}/templates/values.yaml")
  vars = {
    app_gw_subscription_id = var.subscription_id
    app_gw_resource_group  = var.application_gateway.resource_group_name
    app_gw_name            = var.application_gateway.name
  }
}

resource "helm_release" "ingress_azure" {
  chart            = "${path.module}/../../charts/ingress-azure"
  name             = "ingress-azure"
  namespace        = "ingress-azure"
  create_namespace = true
  atomic           = true

  values = [
    data.template_file.ingress_azure.rendered
  ]
}
