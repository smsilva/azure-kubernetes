module "appgw" {
  source = "git@github.com:smsilva/azure-application-gateway.git//src?ref=1.1.0"

  name           = var.name
  resource_group = var.resource_group
  subnet_id      = var.subnet_id
}

output "instance" {
  value = module.appgw.instance
}
