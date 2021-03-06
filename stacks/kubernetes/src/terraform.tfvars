dns_zone                            = "sandbox.wasp.silvios.me"
cluster_base_name                   = "blue"
cluster_location                    = "eastus2"
cluster_version                     = "1.21.9"
cluster_default_node_pool_min_count = 3
cluster_default_node_pool_max_count = 5
cluster_default_node_pool_name      = "system01"
cluster_administrators_ids          = ["d5075d0a-3704-4ed9-ad62-dc8068c7d0e1"] # aks-administrator
argocd_administrators_ids           = ["d5075d0a-3704-4ed9-ad62-dc8068c7d0e1"] # aks-administrator
argocd_contributors_ids             = ["2deb9d06-5807-4107-a5a6-94368f39d79f"] # aks-contributor
argocd_ingress_issuer_name          = "letsencrypt-nginx-staging"
argocd_prefix                       = "argocd-"
install_cert_manager                = true
install_external_secrets            = true
install_external_dns                = true
install_ingress_nginx               = true
install_argocd                      = true
key_vault_name                      = "waspfoundation636a465c"
key_vault_resource_group_name       = "wasp-foundation"
