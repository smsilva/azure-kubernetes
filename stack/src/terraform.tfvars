# environment:
#   id: wasp-na-sbx
#   clusters:
#     - id: wasp-na-sbx-a
#     - id: wasp-na-sbx-b

keyvault_name    = "wasp-na-sbx-a"
cluster_name     = "wasp-na-sbx-a"
cluster_location = "eastus2"
cluster_version  = "1.21.7"

cluster_admin_group_ids = [
  "d5075d0a-3704-4ed9-ad62-dc8068c7d0e1" # aks-administrator
]
