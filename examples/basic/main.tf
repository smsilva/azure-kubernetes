locals {
  platform_instance_name = "crow-sandbox-iq1"
  location               = "centralus"
}

resource "azurerm_virtual_network" "aks" {
  name                = "${local.platform_instance_name}-vnet-private"
  address_space       = ["10.0.0.0/8"]
  location            = local.location
  resource_group_name = local.platform_instance_name
}

resource "azurerm_subnet" "aks" {
  name                 = "aks-subnet"
  address_prefixes     = ["10.240.0.0/16"]
  virtual_network_name = azurerm_virtual_network.aks.name
  resource_group_name  = local.platform_instance_name
}

module "aks" {
  source = "../../src"

  platform_instance_name = local.platform_instance_name
  cluster_name           = "aks"
  cluster_location       = "centralus"
  cluster_version        = "1.20.9"
  subnet_id              = azurerm_subnet.aks.id

  admin_group_object_ids = [
    "d5075d0a-3704-4ed9-ad62-dc8068c7d0e1",
  ]
}

output "aks_id" {
  value = module.aks.aks_id
}

output "aks_kubelet_identity_client_id" {
  value = module.aks.aks_kubelet_identity_client_id
}

output "aks_kubeconfig" {
  value     = module.aks.aks_kubeconfig
  sensitive = true
}
