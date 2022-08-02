data "template_file" "sso" {
  template = file("${path.module}/templates/sso.yaml")
  vars = {
    server_config_url_host       = "${var.cname}.${var.domain}"
    server_config_oidc_client_id = var.sso_application_id
    server_config_oidc_tenant_id = var.tenant_id
  }
}

data "template_file" "ingress_nginx" {
  template = file("${path.module}/templates/ingress-nginx.yaml")
  vars = {
    server_ingress_host        = var.cname
    server_ingress_domain      = var.domain
    server_ingress_issuer_name = var.ingress_issuer_name
  }
}

data "template_file" "ingress_azure" {
  template = file("${path.module}/templates/ingress-application-gateway.yaml")
  vars = {
    server_ingress_host        = var.cname
    server_ingress_domain      = var.domain
    server_ingress_issuer_name = var.ingress_issuer_name
  }
}

locals {
  rbac = templatefile("${path.module}/templates/rbac-config.yaml", {
    server_rbac_config_group_contributors   = var.contributors_ids
    server_rbac_config_group_administrators = var.administrators_ids
  })

  extra_objects = templatefile("${path.module}/templates/extra-objects.yaml", {
    argocd_sso_application_id = var.sso_application_id
  })

  ingress_template = length(regexall(".*application-gateway.*", var.ingress_issuer_name)) > 0 ? data.template_file.ingress_azure.rendered : data.template_file.ingress_nginx.rendered
}

resource "helm_release" "argocd" {
  chart            = "${path.module}/../helm/charts/argo-cd"
  name             = "argocd"
  namespace        = "argocd"
  create_namespace = true
  atomic           = true
  timeout          = 600 # 10 minutes

  values = [
    local.ingress_template,
    data.template_file.sso.rendered,
    file("${path.module}/templates/additional-projects.yaml"),
    file("${path.module}/templates/configs-known-hosts.yaml"),
    file("${path.module}/templates/resource-customizations.yaml"),
    local.extra_objects,
    local.rbac,
  ]

  depends_on = [
    data.template_file.ingress_nginx,
    data.template_file.ingress_azure,
    data.template_file.sso,
  ]
}
