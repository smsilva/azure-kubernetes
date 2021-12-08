provider "azurerm" {
  features {}
}

locals {
  location                = "eastus2"
  cluster_name            = "wasp-aks-example-2"
  resource_group_name     = local.cluster_name
  virtual_network_name    = "${local.cluster_name}-vnet"
  virtual_network_cidrs   = ["10.0.0.0/8"]
  virtual_network_subnets = [{ cidr = "10.140.0.0/16", name = "aks" }]
  admin_group_ids         = ["d5075d0a-3704-4ed9-ad62-dc8068c7d0e1"]
  kubernetes_config_map   = "${path.module}/templates/argocd-bootstrap.yaml"
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

module "aks" {
  source = "../../src"

  cluster_name            = local.cluster_name
  cluster_location        = local.location
  cluster_version         = "1.21.2"
  cluster_subnet_id       = module.vnet.subnets["aks"].instance.id
  cluster_admin_group_ids = local.admin_group_ids
  default_node_pool_name  = "sysnp01" # 12 Alphanumeric characters
  resource_group_name     = azurerm_resource_group.default.name

  depends_on = [
    azurerm_resource_group.default
  ]
}

data "template_file" "argocd_bootstrap" {
  template = file(local.kubernetes_config_map)
  vars = {
    aks_id                 = module.aks.instance.id
    aks_location           = module.aks.instance.location
    aks_vnet_id            = module.vnet.instance.id
    aks_subnet_id          = module.vnet.subnets["aks"].instance.id
  }
}

output "argocd_bootstrap" {
  value = data.template_file.argocd_bootstrap.rendered
}

output "aks_kubeconfig" {
  value     = module.aks.aks_kubeconfig
  sensitive = true
}
