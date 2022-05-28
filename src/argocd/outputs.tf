output "templates" {
  value = {
    argocd_values_sso           = data.template_file.argocd_values_sso.rendered,
    argocd_values_rbac          = local.argocd_values_rbac,
    argocd_values_ingress_nginx = data.template_file.argocd_values_ingress_nginx.rendered,
    argocd_values_extra_objects = local.argocd_values_extra_objects
  }
}
