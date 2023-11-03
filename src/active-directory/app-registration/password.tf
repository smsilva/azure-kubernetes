resource "time_rotating" "default" {
  rotation_days = local.azuread_application_password_rotation_days
}

resource "azuread_application_password" "default" {
  application_id = "/applications/${azuread_application.default.object_id}"
  display_name   = "argocd"
  
  rotate_when_changed = {
    rotation = time_rotating.default.id
  }
}
