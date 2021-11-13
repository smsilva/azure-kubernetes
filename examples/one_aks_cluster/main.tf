locals {
  resource_group_name     = "wasp"
  name                    = "wasp-aks"
  location                = "centralus"
  admin_group_ids         = ["d5075d0a-3704-4ed9-ad62-dc8068c7d0e1"]
  virtual_network_name    = "${local.name}-vnet"
  virtual_network_cidrs   = ["10.0.0.0/8"]
  virtual_network_subnets = [{ cidr = "10.140.0.0/16", name = "aks" }]
}

module "vnet" {
  source = "git@github.com:smsilva/azure-network.git//src/vnet?ref=2.0.0"

  name                = local.virtual_network_name
  cidrs               = local.virtual_network_cidrs
  subnets             = local.virtual_network_subnets
  location            = local.location
  resource_group_name = local.resource_group_name
}

module "aks" {
  source = "../../src"

  cluster_name            = local.name
  cluster_location        = local.location
  cluster_version         = "1.21.2"
  cluster_subnet_id       = module.vnet.subnets["aks"].instance.id
  cluster_admin_group_ids = local.admin_group_ids
  default_node_pool_name  = "system" # 12 Alphanumeric characters
  resource_group_name     = local.resource_group_name
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
