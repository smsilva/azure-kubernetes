# environment:
#   id: wasp-sbx-na
#   clusters:
#     - id: wasp-sbx-na-eus2
#     - id: wasp-sbx-na-ceus

keyvault_name    = "wasp-sbx-na-eus2"
cluster_name     = "wasp-sbx-na-eus2"
cluster_location = "eastus2"
cluster_version  = "1.21.7"

cluster_admin_group_ids = [
  "805a3d92-4178-4ad1-a0d6-70eae41a463a", # cloud-admin
]

# wasp-sbx-na-eus2.eastus2.cloudapp.azure.com
