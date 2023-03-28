output "templates" {
  value = {
    sso           = data.template_file.sso.rendered
    rbac          = local.rbac
    extra_objects = local.extra_objects
  }
}
