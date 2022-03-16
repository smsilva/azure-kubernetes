resource "random_string" "id" {
  length      = 3
  min_lower   = 1
  min_numeric = 2
  lower       = true
  special     = false
}

locals {
  virtual_network_name  = local.cluster_name
  virtual_network_cidrs = ["10.244.0.0/14"] #####  10.244.0.1  -  10.247.255.254  -  262.142
  virtual_network_subnets = [
    { cidr = "10.246.0.0/16", name = "aks" },   #  10.246.0.1  -  10.246.255.254  -   65.534
    { cidr = "10.247.2.0/27", name = "app-gw" } #  10.247.2.1  -  10.247.2.30     -       30
  ]
}

resource "azurerm_resource_group" "default" {
  name     = local.resource_group_name
  location = local.location
}

module "vnet" {
  source = "git@github.com:smsilva/azure-network.git//src/vnet?ref=3.0.5"

  name                = local.virtual_network_name
  cidrs               = local.virtual_network_cidrs
  subnets             = local.virtual_network_subnets
  resource_group_name = azurerm_resource_group.default.name

  depends_on = [
    azurerm_resource_group.default
  ]
}
