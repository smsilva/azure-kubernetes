module "vnet" {
  source = "git@github.com:smsilva/azure-network.git//src/vnet?ref=2.0.0"

  name                = local.virtual_network_name
  cidrs               = local.virtual_network_cidrs
  subnets             = local.virtual_network_subnets
  resource_group_name = data.azurerm_resource_group.default.name
  location            = var.location
}

module "aks" {
  source = "git@github.com:smsilva/azure-kubernetes.git//src?ref=main"

  cluster_name            = local.cluster_name
  cluster_location        = var.location
  cluster_version         = "1.21.2"
  cluster_subnet_id       = module.vnet.subnets["aks"].instance.id
  cluster_admin_group_ids = local.admin_group_ids
  default_node_pool_name  = "system" # 12 Alphanumeric characters
  resource_group_name     = data.azurerm_resource_group.default.name
}
