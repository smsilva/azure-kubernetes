locals {
  cluster_name            = var.name
  admin_group_ids         = ["d5075d0a-3704-4ed9-ad62-dc8068c7d0e1"]
  virtual_network_name    = "${local.cluster_name}-vnet-private"
  virtual_network_cidrs   = ["10.0.0.0/8"]
  virtual_network_subnets = [{ cidr = "10.140.0.0/16", name = "aks" }]
  resource_group_name     = var.resource_group_name != "" ? var.resource_group_name : local.cluster_name
}

data "azurerm_resource_group" "default" {
  name = local.resource_group_name
}
