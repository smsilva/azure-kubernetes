resource "helm_release" "argocd" {
  count            = var.install_argocd ? 1 : 0
  chart            = "${path.module}/charts/argocd"
  name             = "argocd"
  namespace        = "argocd"
  create_namespace = true
  atomic           = true
  timeout          = 600 # 10 minutes

  values = [
    data.template_file.argocd_values_sso.rendered,
    data.template_file.argocd_values_rbac.rendered,
    file("${path.module}/templates/argocd-values-configs-known-hosts.yaml"),
    file("${path.module}/templates/argocd-values-additional-projects.yaml"),
    file("${path.module}/templates/argocd-values-extra-objects.yaml"),
  ]

  depends_on = [
    helm_release.cert_manager,
    helm_release.external_secrets,
    helm_release.external_secrets_config,
    helm_release.external_dns
  ]
}
