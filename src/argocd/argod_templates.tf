data "template_file" "argocd_values_sso" {
  template = file("${path.module}/templates/argocd-values-sso.yaml")
  vars = {
    server_config_url_host       = var.url
    server_config_oidc_client_id = var.argocd_sso_application_id
    server_config_oidc_tenant_id = data.azurerm_client_config.current.tenant_id
  }
}

data "template_file" "argocd_values_rbac" {
  template = file("${path.module}/templates/argocd-values-rbac-config.yaml")
  vars = {
    server_rbac_config_group_admin       = var.argocd_rbac_group_admin
    server_rbac_config_group_contributor = var.argocd_rbac_group_contributor
  }
}

data "template_file" "argocd_values_ingress_nginx" {
  template = file("${path.module}/templates/argocd-values-ingress-nginx.yaml")
  vars = {
    server_ingress_host        = var.url
    server_ingress_issuer_name = var.ingress_issuer_name
  }
}
