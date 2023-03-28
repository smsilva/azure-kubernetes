output "dns" {
  value = {
    cname_application_gateway = module.application_gateway.application_gateway_public_ip_fqdn
    cname_ingress             = "${local.cname_record_ingress}.${local.dns_zone}"
  }
}
