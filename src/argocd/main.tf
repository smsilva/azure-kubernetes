data "template_file" "nginx_ingress_controller" {
  template = file("${path.module}/templates/ingress-nginx-values.yaml")
  vars = {
    controller_service_annotations_azure_dns_label_name = var.cluster_instance.name
  }
}

resource "helm_release" "nginx_ingress_controller" {
  count            = var.install_nginx_ingress_controller ? 1 : 0
  chart            = "${path.module}/charts/ingress-nginx"
  name             = "ingress-nginx"
  namespace        = "ingress-nginx"
  create_namespace = true
  atomic           = true

  values = [
    data.template_file.nginx_ingress_controller.rendered
  ]
}

resource "helm_release" "cert_manager" {
  count            = var.install_cert_manager ? 1 : 0
  chart            = "${path.module}/charts/cert-manager-v1.7.2.tgz"
  name             = "cert-manager"
  namespace        = "cert-manager"
  create_namespace = true
  atomic           = true

  set {
    name  = "installCRDs"
    value = "true"
  }
}

resource "helm_release" "cert_manager_issuers" {
  count            = var.install_cert_manager ? 1 : 0
  chart            = "${path.module}/charts/cert-manager-issuers"
  name             = "cert-manager-issuers"
  namespace        = "cert-manager"
  create_namespace = true
  atomic           = true

  depends_on = [
    helm_release.cert_manager
  ]
}

resource "helm_release" "external_secrets" {
  count            = var.install_external_secrets ? 1 : 0
  chart            = "${path.module}/charts/external-secrets-0.4.4.tgz"
  name             = "external-secrets"
  namespace        = "external-secrets"
  create_namespace = true
  atomic           = true
}

data "template_file" "external_secrets_config_values" {
  template = file("${path.module}/templates/external-secrets-config-values.yaml")
  vars = {
    secret_data_arm_client_id           = data.azurerm_client_config.current.client_id,
    cluster_secret_store_arm_tenant_id  = data.azurerm_client_config.current.tenant_id,
    cluster_secret_store_key_vault_name = var.armKeyVaultName
  }
}

resource "helm_release" "external_secrets_config" {
  count            = var.install_external_secrets ? 1 : 0
  chart            = "${path.module}/charts/external-secrets-config"
  name             = "external-secrets-config"
  namespace        = "external-secrets"
  create_namespace = true
  atomic           = true

  set {
    name  = "secret.data.armClientSecret"
    value = base64encode(var.armClientSecret)
  }

  values = [
    data.template_file.external_secrets_config_values.rendered,
  ]

  depends_on = [
    helm_release.external_secrets
  ]
}

resource "helm_release" "external_dns" {
  count            = var.install_external_dns ? 1 : 0
  chart            = "${path.module}/charts/external-dns"
  name             = "external-dns"
  namespace        = "external-dns"
  create_namespace = true
  atomic           = true

  depends_on = [
    helm_release.external_secrets_config
  ]
}
