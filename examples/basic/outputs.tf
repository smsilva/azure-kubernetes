output "id" {
  value = module.aks.id
}

output "name" {
  value = module.aks.instance.name
}

output "kubelet_identity_client_id" {
  value = module.aks.kubelet_identity_client_id
}

output "identity_object_id" {
  value = module.aks.identity_object_id
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
  value     = module.aks.instance.kube_admin_config[0].host
  sensitive = true
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

output "templates" {
  value = module.argocd.templates
}
