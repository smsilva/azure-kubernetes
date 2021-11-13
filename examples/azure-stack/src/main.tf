module "vnet" {
  source = "git@github.com:smsilva/azure-network.git//src/vnet?ref=1.1.0"

  name     = local.virtual_network_name
  location = local.location
  cidrs    = local.virtual_network_cidrs
  subnets  = local.virtual_network_subnets
}

module "aks" {
  source = "git@github.com:smsilva/azure-kubernetes.git//src?ref=main"

  cluster_name            = var.name
  cluster_location        = var.location
  cluster_version         = "1.21.2"
  cluster_subnet_id       = module.vnet.subnets["aks"].instance.id
  cluster_admin_group_ids = local.admin_group_ids
  default_node_pool_name  = "system" # 12 Alphanumeric characters
}
