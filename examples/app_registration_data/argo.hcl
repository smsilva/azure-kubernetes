# data.azuread_application.argocd:
data "azuread_application" "argocd" {
    api                            = [
        {
            known_client_applications      = []
            mapped_claims_enabled          = false
            oauth2_permission_scopes       = []
            requested_access_token_version = 2
        },
    ]
    app_role_ids                   = {}
    app_roles                      = []
    application_id                 = "5b59d3e0-04f4-4be4-aff4-b159a8ed4b46"
    device_only_auth_enabled       = false
    disabled_by_microsoft          = "<nil>"
    display_name                   = "argocd"
    fallback_public_client_enabled = false
    feature_tags                   = [
        {
            custom_single_sign_on = false
            enterprise            = false
            gallery               = false
            hide                  = false
        },
    ]
    group_membership_claims        = [
        "All",
    ]
    id                             = "d2e6c72d-cca9-4dff-a8dc-b35644f39755"
    identifier_uris                = []
    oauth2_permission_scope_ids    = {}
    oauth2_post_response_required  = false
    object_id                      = "d2e6c72d-cca9-4dff-a8dc-b35644f39755"
    optional_claims                = [
        {
            access_token = [
                {
                    additional_properties = []
                    essential             = false
                    name                  = "groups"
                    source                = ""
                },
            ]
            id_token     = [
                {
                    additional_properties = []
                    essential             = false
                    name                  = "groups"
                    source                = ""
                },
            ]
            saml2_token  = []
        },
    ]
    owners                         = [
        "a857f388-8e87-4628-bfdb-11752d8a7051",
    ]
    public_client                  = [
        {
            redirect_uris = []
        },
    ]
    publisher_domain               = "smsilvagmail.onmicrosoft.com"
    required_resource_access       = [
        {
            resource_access = [
                {
                    id   = "9728c0c4-a06b-4e0e-8d1b-3d694e8ec207"
                    type = "Role"
                },
                {
                    id   = "6c2d1b1d-a490-4178-ba6b-7efceda9129b"
                    type = "Role"
                },
            ]
            resource_app_id = "00000002-0000-0000-c000-000000000000"
        },
    ]
    sign_in_audience               = "AzureADandPersonalMicrosoftAccount"
    single_page_application        = [
        {
            redirect_uris = []
        },
    ]
    tags                           = []
    web                            = [
        {
            homepage_url   = ""
            implicit_grant = [
                {
                    access_token_issuance_enabled = true
                    id_token_issuance_enabled     = true
                },
            ]
            logout_url     = ""
            redirect_uris  = [
                "https://argocd.centralus.sandbox.wasp.silvios.me/auth/callback",
                "https://argocd.eastus2.sandbox.wasp.silvios.me/auth/callback",
                "https://argocd-green.centralus.sandbox.wasp.silvios.me/auth/callback",
                "https://argocd-blue.centralus.sandbox.wasp.silvios.me/auth/callback",
                "https://argocd-green.eastus2.sandbox.wasp.silvios.me/auth/callback",
                "https://argocd-blue.eastus2.sandbox.wasp.silvios.me/auth/callback",
                "https://argocd.sandbox.wasp.silvios.me/auth/callback",
                "https://oidcdebugger.com/debug",
            ]
        },
    ]
}
