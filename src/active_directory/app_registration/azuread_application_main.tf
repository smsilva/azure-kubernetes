data "azuread_client_config" "current" {}

locals {
  azuread_application_name                   = var.name
  azuread_application_host                   = "${var.name}.${var.dns_zone}"
  azuread_application_password_rotation_days = "120"
}

resource "azuread_application" "default" {
  display_name            = local.azuread_application_name
  identifier_uris         = ["api://${local.azuread_application_name}"]
  logo_image              = null
  owners                  = [data.azuread_client_config.current.object_id]
  sign_in_audience        = "AzureADandPersonalMicrosoftAccount"
  group_membership_claims = ["All"]

  api {
    mapped_claims_enabled          = true
    requested_access_token_version = 2

    known_client_applications = []
  }

  feature_tags {
    enterprise = false
    gallery    = false
  }

  optional_claims {
    access_token {
      name = "groups"
    }

    id_token {
      name                  = "groups"
      essential             = false
      additional_properties = []
    }
  }

  required_resource_access {
    resource_app_id = "00000003-0000-0000-c000-000000000000" # Microsoft Graph

    resource_access {
      id   = "37f7f235-527c-4136-accd-4a02d197296e" # openid
      type = "Role"
    }

    resource_access {
      id   = "64a6cdd6-aab1-4aaf-94b8-3cc8405e90d0" # email
      type = "Role"
    }

    resource_access {
      id   = "14dad69e-099b-42c9-810b-d002981feec1" # profile
      type = "Role"
    }
  }

  web {
    homepage_url = "https://${local.azuread_application_host}"
    logout_url   = "https://${local.azuread_application_host}/logout"

    redirect_uris = [
      "https://${local.azuread_application_host}/auth/callback",
      "https://oidcdebugger.com/debug",
    ]

    implicit_grant {
      access_token_issuance_enabled = true
      id_token_issuance_enabled     = true
    }
  }
}
