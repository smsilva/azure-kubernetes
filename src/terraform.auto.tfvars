name                    = "sandbox"
resource_group_name     = "sandbox"
resource_group_location = "eastus2"
kubernetes_version      = "1.28.12"
subnet_name             = "aks"
virtual_network_cidrs   = ["10.244.0.0/14"]
virtual_network_subnets = [
  { cidr = "10.246.0.0/16", name = "aks" },
  { cidr = "10.245.0.0/28", name = "application_gateway" },
]
administrators_ids = [
  # "d5075d0a-3704-4ed9-ad62-dc8068c7d0e1", # aks-administrator
  "93141ff6-7017-4c67-bf01-0905ecad1a90",
  "dc0c57aa-970c-4e02-b732-849b9c6e55bf",
]
