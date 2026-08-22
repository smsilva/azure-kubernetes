output "templates" {
  value = {
    sso           = local.sso
    rbac          = local.rbac
    extra_objects = local.extra_objects
  }
}
