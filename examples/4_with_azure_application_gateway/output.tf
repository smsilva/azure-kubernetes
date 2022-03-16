output "id" {
  value = module.aks.aks_id
}

output "name" {
  value = module.aks.instance.name
}

output "kubelet_identity_client_id" {
  value = module.aks.aks_kubelet_identity_client_id
}

output "kubeconfig" {
  value     = module.aks.aks_kubeconfig
  sensitive = true
}

output "instance" {
  value     = module.aks.instance
  sensitive = true
}

output "api_server" {
  value = module.aks.instance.kube_admin_config[0].host
}

output "api_token" {
  value     = module.aks.instance.kube_admin_config[0].password
  sensitive = true
}

output "client_certificate" {
  value     = module.aks.instance.kube_admin_config[0].client_certificate
  sensitive = true
}

output "cluster_ca_certificate" {
  value     = module.aks.instance.kube_admin_config[0].cluster_ca_certificate
  sensitive = true
}

output "application_gateway_id" {
  value = module.application_gateway.instance.id
}
