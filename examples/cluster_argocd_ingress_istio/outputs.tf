output "url_gateway" {
  value = "gateway.${local.cluster_random_id}.${local.dns_zone}"
}

output "url_argocd" {
  value = "argocd.${local.cluster_random_id}.${local.dns_zone}"
}

output "url_httpbin" {
  value = "httpbin.${local.cluster_random_id}.${local.dns_zone}"
}

output "cluster_name" {
  value = local.cluster_name
}

output "cluster_resource_group_name" {
  value = local.cluster_resource_group_name
}

output "argocd_access_group_name" {
  value = local.install_argocd ? module.cluster_access_group[0].display_name : null
}