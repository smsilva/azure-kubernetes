data "template_file" "external_dns" {
  template = file("${path.module}/templates/values.yaml")
  vars = {
    domain = var.domain
  }
}

resource "helm_release" "external_dns_config" {
  chart            = "${path.module}/../../charts/external-dns-config"
  name             = "${var.name}-config"
  namespace        = var.namespace
  create_namespace = true
  atomic           = true

  set {
    name = "tenantId"
    value = var.tenantId
  }

  set {
    name = "subscriptionId"
    value = var.subscriptionId
  }

  set {
    name = "resourceGroup"
    value = var.resourceGroup
  }
}

resource "helm_release" "external_dns" {
  chart            = "${path.module}/../../charts/external-dns"
  name             = var.name
  namespace        = var.namespace
  create_namespace = true
  atomic           = true

  values = [
    data.template_file.external_dns.rendered,
  ]

  depends_on = [
    helm_release.external_dns_config,    
  ]
}
