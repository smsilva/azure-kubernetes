keyvault_name                    = "waspfoundation636a465c"
keyvault_resource_group_name     = "wasp-foundation"
cluster_name                     = "wasp-sandbox"
cluster_location                 = "centralus"
cluster_version                  = "1.21.9"
argocd_url                       = "argocd.centralus.sandbox.wasp.silvios.me"
install_cert_manager             = true
install_external_secrets         = true
install_external_dns             = true
install_nginx_ingress_controller = true
install_argocd                   = true
argocd_rbac_group_admin          = "d5075d0a-3704-4ed9-ad62-dc8068c7d0e1" # aks-administrator
argocd_rbac_group_contributor    = "2deb9d06-5807-4107-a5a6-94368f39d79f" # aks-contributor
argocd_ingress_issuer_name       = "letsencrypt-staging-nginx"

cluster_admin_group_ids = [
  "805a3d92-4178-4ad1-a0d6-70eae41a463a", # cloud-admin
  "d5075d0a-3704-4ed9-ad62-dc8068c7d0e1", # aks-administrator
]
