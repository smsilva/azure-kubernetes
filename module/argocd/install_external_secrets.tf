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
