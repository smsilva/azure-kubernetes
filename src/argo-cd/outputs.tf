output "templates" {
  value = {
    sso           = data.template_file.sso.rendered
    ingress_nginx = data.template_file.ingress_nginx.rendered
    rbac          = local.rbac
    extra_objects = local.extra_objects
  }
}
