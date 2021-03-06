output "id" {
  value = module.aks.id
}

output "name" {
  value = module.aks.instance.name
}

output "kubelet_identity_id" {
  value = module.aks.instance.kubelet_identity[0].user_assigned_identity_id
}

output "kubelet_identity_client_id" {
  value = module.aks.kubelet_identity_client_id
}

output "kubelet_identity_object_id" {
  value = module.aks.instance.kubelet_identity[0].object_id
}

output "kubeconfig" {
  value     = module.aks.kubeconfig
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
  value = module.appgw.application_gateway_id
}

output "application_gateway_name" {
  value = module.appgw.application_gateway_name
}

output "application_gateway_resource_group_name" {
  value = module.appgw.application_gateway_resource_group_name
}
