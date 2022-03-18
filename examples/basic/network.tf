locals {
  virtual_network_name    = "${local.cluster_name}-vnet"
  virtual_network_cidrs   = ["10.244.0.0/14"]
  virtual_network_subnets = [{ cidr = "10.246.0.0/16", name = "aks" }]
}

module "vnet" {
  source = "git@github.com:smsilva/azure-network.git//src/vnet?ref=3.0.5"

  name                = local.virtual_network_name
  cidrs               = local.virtual_network_cidrs
  subnets             = local.virtual_network_subnets
  resource_group_name = azurerm_resource_group.default.name
}