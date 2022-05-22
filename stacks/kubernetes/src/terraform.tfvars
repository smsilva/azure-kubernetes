keyvault_name                = "waspfoundation636a465c"
keyvault_resource_group_name = "wasp-foundation"
cluster_name                 = "wasp-sandbox"
cluster_location             = "centralus"
cluster_version              = "1.21.9"
argocd_url                   = "argocd.sandbox.wasp.silvios.me"
install_cert_manager         = true
install_external_secrets     = true
install_argocd               = true

cluster_admin_group_ids = [
  "805a3d92-4178-4ad1-a0d6-70eae41a463a", # cloud-admin
]
