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
