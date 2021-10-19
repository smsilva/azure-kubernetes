

module "vnet" {
  source = "git@github.com:smsilva/azure-network.git//src/vnet?ref=1.1.0"

  platform_instance_name = var.platform_instance_name
  location               = local.location
  name                   = local.virtual_network_name
  cidrs                  = local.virtual_network_cidrs
  subnets                = local.virtual_network_subnets
}

module "aks" {
  source = "git@github.com:smsilva/azure-kubernetes.git//src/vnet?ref=1.1.0"

  platform_instance_name  = var.platform_instance_name
  cluster_location        = "centralus"
  cluster_version         = "1.21.2"
  cluster_subnet_id       = module.vnet.subnets["aks"].instance.id
  cluster_admin_group_ids = local.admin_group_ids
  default_node_pool_name  = "sbxsyspool" # 12 Alphanumeric characters
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
