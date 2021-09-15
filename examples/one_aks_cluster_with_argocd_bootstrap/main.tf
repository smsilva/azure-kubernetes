locals {
  location                = "centralus"
  admin_group_ids         = ["d5075d0a-3704-4ed9-ad62-dc8068c7d0e1"]
  virtual_network_name    = "aks-vnet-private"
  virtual_network_cidrs   = ["10.0.0.0/8"]
  virtual_network_subnets = [{ cidr = "10.140.0.0/16", name = "aks" }]
  kubernetes_config_map   = "${path.module}/templates/argocd-bootstrap.yaml"
}

module "vnet" {
  source = "git@github.com:smsilva/azure-network.git//src/vnet?ref=1.0.0"

  platform_instance_name = var.platform_instance_name
  location               = local.location
  name                   = local.virtual_network_name
  cidrs                  = local.virtual_network_cidrs
  subnets                = local.virtual_network_subnets
}

module "aks" {
  source = "../../src"

  platform_instance_name  = var.platform_instance_name
  cluster_location        = "centralus"
  cluster_version         = "1.21.2"
  cluster_subnet_id       = module.vnet.subnets["aks"].instance.id
  cluster_admin_group_ids = local.admin_group_ids
}

data "template_file" "argocd_bootstrap" {
  template = file(local.kubernetes_config_map)
  vars = {
    platform_instance_name = var.platform_instance_name
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
