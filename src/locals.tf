locals {
  cluster_name             = "${var.cluster_name}-${random_string.aks_id.result}"
  resource_group_name      = "${var.cluster_name}-${random_string.aks_id.result}"
  node_resource_group_name = "${var.cluster_name}-${random_string.aks_id.result}-nrg"
  cluster_dns_prefix       = "${var.cluster_name}-${random_string.aks_id.result}"
}
