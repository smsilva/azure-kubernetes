locals {
  sso = templatefile("${path.module}/templates/sso.yaml", {
    server_config_url_host       = "${var.cname}.${var.domain}"
    server_config_oidc_client_id = var.sso_application_id
    server_config_oidc_tenant_id = var.tenant_id
  })

  rbac = templatefile("${path.module}/templates/rbac-config.yaml", {
    server_rbac_config_group_contributors   = var.contributors_ids
    server_rbac_config_group_administrators = var.administrators_ids
  })

  extra_objects = templatefile("${path.module}/templates/extra-objects.yaml", {
    argocd_sso_application_id = var.sso_application_id
  })

  notifications = templatefile("${path.module}/templates/notifications.yaml", {
    server_config_url_host = "${var.cname}.${var.domain}"
  })

  configs_server = templatefile("${path.module}/templates/configs-server.yaml", {
    configs_params_server_insecure = var.cluster_ingress_type == "nginx" ? "false" : "true"
  })
}

resource "helm_release" "argocd" {
  chart            = "${path.module}/../../charts/argo-cd"
  name             = "argocd"
  namespace        = "argocd"
  create_namespace = true
  atomic           = true
  timeout          = 600 # 10 minutes

  values = [
    local.sso,
    file("${path.module}/templates/resource-customizations.yaml"),
    local.configs_server,
    local.extra_objects,
    local.rbac,
  ]
}

locals {
  argocd_config = templatefile("${path.module}/templates/ingress-config.yaml", {
    global_environment_id                          = var.environment_id
    global_environment_domain                      = var.domain
    global_environment_cluster_name                = var.cluster_name
    global_environment_cluster_ingress_type        = var.cluster_ingress_type
    global_environment_cluster_certificates_type   = var.cluster_certificates_type
    global_environment_cluster_certificates_server = var.cluster_certificates_server
    charts_ingress_azure_enabled                   = var.cluster_ingress_type == "azure" ? "true" : "false"
    charts_ingress_nginx_enabled                   = var.cluster_ingress_type == "nginx" ? "true" : "false"
  })
}

resource "helm_release" "argocd_config" {
  chart            = "${path.module}/../../charts/argo-cd-config"
  name             = "argocd-config"
  namespace        = "argocd"
  create_namespace = true
  atomic           = true
  timeout          = 600 # 10 minutes

  values = [
    local.argocd_config,
  ]

  depends_on = [
    helm_release.argocd
  ]
}
