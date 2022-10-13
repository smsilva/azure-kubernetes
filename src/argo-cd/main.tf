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

data "template_file" "ingress_istio" {
  template = file("${path.module}/templates/ingress-istio.yaml")
}

locals {
  rbac = templatefile("${path.module}/templates/rbac-config.yaml", {
    server_rbac_config_group_contributors   = var.contributors_ids
    server_rbac_config_group_administrators = var.administrators_ids
  })

  extra_objects = templatefile("${path.module}/templates/extra-objects.yaml", {
    argocd_sso_application_id = var.sso_application_id
  })

  ingress_template_first = length(regexall(".*azure.*", var.ingress_issuer_name)) > 0 ? data.template_file.ingress_azure.rendered : data.template_file.ingress_nginx.rendered
  ingress_template_final = length(regexall(".*istio.*", var.ingress_issuer_name)) > 0 ? data.template_file.ingress_istio.rendered : local.ingress_template_first
}

resource "helm_release" "argocd" {
  chart            = "${path.module}/../helm/charts/argo-cd"
  name             = "argocd"
  namespace        = "argocd"
  create_namespace = true
  atomic           = true
  timeout          = 600 # 10 minutes

  values = [
    data.template_file.sso.rendered,
    file("${path.module}/templates/configs-known-hosts.yaml"),
    file("${path.module}/templates/extra-volumes.yaml"),
    file("${path.module}/templates/high-availability.yaml"),
    file("${path.module}/templates/metrics.yaml"),
    file("${path.module}/templates/resource-customizations.yaml"),
    file("${path.module}/templates/server.yaml"),
    local.extra_objects,
    local.ingress_template_final,
    local.rbac,
  ]

  depends_on = [
    data.template_file.ingress_nginx,
    data.template_file.ingress_azure,
    data.template_file.sso,
  ]
}

data "template_file" "argocd_config" {
  template = file("${path.module}/templates/ingress-config.yaml")
  vars = {
    global_environment_id                          = var.environment_id
    global_environment_domain                      = var.domain
    global_environment_cluster_name                = var.cluster_name
    global_environment_cluster_ingress_type        = var.cluster_ingress_type
    global_environment_cluster_certificates_type   = var.cluster_certificates_type
    global_environment_cluster_certificates_server = var.cluster_certificates_server
    charts_ingress_azure_enabled                   = "true"
    charts_ingress_nginx_enabled                   = "false"
  }
}

resource "helm_release" "argocd_config" {
  chart            = "${path.module}/../helm/charts/argo-cd-config"
  name             = "argocd-config"
  namespace        = "argocd"
  create_namespace = true
  atomic           = true
  timeout          = 600 # 10 minutes

  values = [
    data.template_file.argocd_config.rendered,
  ]

  depends_on = [
    helm_release.argocd
  ]
}
