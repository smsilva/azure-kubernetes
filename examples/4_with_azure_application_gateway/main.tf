locals {
  location = "eastus2"

  cluster_name    = "wasp-aks-example-4-${random_string.id.result}"
  cluster_version = "1.21.7"

  resource_group_name = local.cluster_name

  admin_group_ids = [
    "d5075d0a-3704-4ed9-ad62-dc8068c7d0e1" # aks-administrator
  ]
}

module "aks" {
  source = "../../src"

  cluster_name            = local.cluster_name
  cluster_location        = local.location
  cluster_version         = local.cluster_version
  cluster_subnet_id       = module.vnet.subnets["aks"].instance.id
  cluster_admin_group_ids = local.admin_group_ids
  resource_group_name     = azurerm_resource_group.default.name
  default_node_pool_name  = "npsys01" # 12 Alphanumeric characters

  depends_on = [
    module.vnet
  ]
}

module "application_gateway" {
  source = "git@github.com:smsilva/azure-application-gateway.git//src?ref=development"

  name      = "${local.cluster_name}-agw"
  location  = local.location
  subnet_id = module.vnet.subnets["app-gw"].instance.id
}
