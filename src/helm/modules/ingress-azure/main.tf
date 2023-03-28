data "template_file" "ingress_azure" {
  template = file("${path.module}/templates/values.yaml")
  vars = {
    app_gw_subscription_id = var.subscription_id
    app_gw_resource_group  = var.application_gateway.resource_group_name
    app_gw_name            = var.application_gateway.name
  }
}

data "template_file" "ingress_azure_secret" {
  template = file("${path.module}/templates/service-principal.json")
  vars = {
    arm_tenant_id       = var.tenant_id
    arm_subscription_id = var.subscription_id
    arm_client_id       = var.client_id
    arm_client_secret   = var.client_secret
  }
}

resource "helm_release" "ingress_azure" {
  chart            = "${path.module}/../../charts/ingress-azure"
  name             = "ingress-azure"
  namespace        = "ingress-azure"
  create_namespace = true
  atomic           = false
  timeout          = 240 # 4 minutes

  values = [
    data.template_file.ingress_azure.rendered
  ]

  set_sensitive {
    name  = "armAuth.secretJSON"
    value = base64encode(data.template_file.ingress_azure_secret.rendered)
  }
}
