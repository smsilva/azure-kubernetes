resource_group_name = "wasp-sandbox"
cluster_name        = "wasp-sandbox"
cluster_location    = "eastus2"
cluster_version     = "1.21.7"
cluster_admin_group_ids = [
  "d5075d0a-3704-4ed9-ad62-dc8068c7d0e1" # aks-administrator
]

keyvault_resource_group_name = "wasp-foundation"
keyvault_name = "waspfoundation636a465c"
