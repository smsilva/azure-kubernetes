data "template_file" "argocd_values_sso" {
  template = file("${path.module}/templates/argocd-values-sso.yaml")
  vars = {
    server_config_url_host       = var.host
    server_config_oidc_client_id = var.sso_application_id
    server_config_oidc_tenant_id = data.azurerm_client_config.current.tenant_id
  }
}

data "template_file" "argocd_values_rbac" {
  template = file("${path.module}/templates/argocd-values-rbac-config.yaml")
  vars = {
    server_rbac_config_group_admin       = var.rbac_group_admin
    server_rbac_config_group_contributor = var.rbac_group_contributor
  }
}

data "template_file" "argocd_values_ingress_nginx" {
  template = file("${path.module}/templates/argocd-values-ingress-nginx.yaml")
  vars = {
    server_ingress_host        = var.host
    server_ingress_issuer_name = var.ingress_issuer_name
  }
}

resource "helm_release" "argocd" {
  count            = var.install_argocd ? 1 : 0
  chart            = "${path.module}/charts/argocd"
  name             = "argocd"
  namespace        = "argocd"
  create_namespace = true
  atomic           = true
  timeout          = 600 # 10 minutes

  values = [
    data.template_file.argocd_values_ingress_nginx.rendered,
    data.template_file.argocd_values_rbac.rendered,
    data.template_file.argocd_values_sso.rendered,
    file("${path.module}/templates/argocd-values-additional-projects.yaml"),
    file("${path.module}/templates/argocd-values-configs-known-hosts.yaml"),
    file("${path.module}/templates/argocd-values-extra-objects.yaml"),
  ]

  depends_on = [
    data.template_file.argocd_values_ingress_nginx,
    data.template_file.argocd_values_rbac,
    data.template_file.argocd_values_sso,
    helm_release.cert_manager_issuers,
    helm_release.cert_manager,
    helm_release.external_dns,
    helm_release.external_secrets_config,
    helm_release.external_secrets,
    helm_release.nginx_ingress_controller,
  ]
}
