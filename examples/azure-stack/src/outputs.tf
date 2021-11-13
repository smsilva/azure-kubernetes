#output "aks_id" {
#  value = module.aks.aks_id
#}
#
#output "aks_kubelet_identity_client_id" {
#  value = module.aks.aks_kubelet_identity_client_id
#}
#
#output "aks_kubeconfig" {
#  value     = module.aks.aks_kubeconfig
#  sensitive = true
#}

output "cluster_name" {
  value = local.cluster_name
}

output "vnet_id" {
  value = module.vnet.id
}

output "virtual_network_name" {
  value = local.virtual_network_name
}
