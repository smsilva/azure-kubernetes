resource "helm_release" "external_secrets" {
  chart            = "${path.module}/../../charts/external-secrets"
  name             = "external-secrets"
  namespace        = "external-secrets"
  create_namespace = true
  atomic           = true

  set = [
    {
      name  = "serviceAccount.annotations.azure\\.workload\\.identity/client-id"
      value = var.identity_client_id
    },
    {
      name  = "podLabels.azure\\.workload\\.identity/use"
      value = "true"
      type  = "string"
    }
  ]
}

data "template_file" "external_secrets_config_values" {
  template = file("${path.module}/templates/values.yaml")
  vars = {
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