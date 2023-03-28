output "url_gateway" {
  value = "gateway.${local.cluster_random_id}.${local.dns_zone}"
}