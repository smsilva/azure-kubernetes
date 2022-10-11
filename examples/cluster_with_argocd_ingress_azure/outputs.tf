output "application_gateway_public_ip_fqdn" {
  value = module.application_gateway.application_gateway_public_ip_fqdn
}

output "inboud_cname" {
  value = "${local.ingress_cname_record}.${local.dns_zone}"
}

output "dns" {
  value = {
    cname_application_gateway = module.application_gateway.application_gateway_public_ip_fqdn
    cname_inbound             = "${local.ingress_cname_record}.${local.dns_zone}"
  }
}
