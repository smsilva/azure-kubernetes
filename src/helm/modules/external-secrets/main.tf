resource "helm_release" "external_secrets" {
  chart            = "${path.module}/../../charts/external-secrets"
  name             = "external-secrets"
  namespace        = "external-secrets"
  create_namespace = true
  atomic           = true
}

data "template_file" "external_secrets_config_values" {
  template = file("${path.module}/templates/values.yaml")
  vars = {
    secret_data_arm_client_id           = var.client_id
    cluster_secret_store_arm_tenant_id  = var.tenant_id
    cluster_secret_store_key_vault_name = var.key_vault_name
  }
}

resource "helm_release" "external_secrets_config" {
  chart            = "${path.module}/../../charts/external-secrets-config"
  name             = "external-secrets-config"
  namespace        = "external-secrets"
  create_namespace = true
  atomic           = true

  set_sensitive {
    name  = "secret.data.armClientSecret"
    value = base64encode(var.client_secret)
  }

  values = [
    data.template_file.external_secrets_config_values.rendered,
  ]

  depends_on = [
    helm_release.external_secrets
  ]
}

output "template" {
  value     = data.template_file.external_secrets_config_values.rendered
  sensitive = true
}
