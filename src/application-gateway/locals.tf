locals {
  application_gateway_name               = var.name
  public_ip_name                         = var.name
  backend_address_pool_name              = "${var.name}-be-ap"
  frontend_port_name                     = "${var.name}-fe-port"
  frontend_ip_configuration_name         = "${var.name}-fe-ip"
  frontend_ip_configuration_name_private = "${var.name}-fe-ip-pvt"
  http_setting_name                      = "${var.name}-be-htst"
  listener_name                          = "${var.name}-http-listener"
  request_routing_rule_name              = "${var.name}-rqrt"
  tags                                   = var.tags
}
