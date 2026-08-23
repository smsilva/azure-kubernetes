resource "helm_release" "cert_manager" {
  chart            = "${path.module}/../../charts/cert-manager"
  name             = "cert-manager"
  namespace        = "cert-manager"
  create_namespace = true
  atomic           = true

  set = [
    {
      name  = "installCRDs"
      value = "true"
    },
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

resource "helm_release" "cert_manager_issuers" {
  chart            = "${path.module}/../../charts/cert-manager-issuers"
  name             = "cert-manager-issuers"
  namespace        = "cert-manager"
  create_namespace = true
  atomic           = true

  set = [
    {
      name  = "fqdn"
      value = var.fqdn
    },
    {
      name  = "azureDNS.subscriptionID"
      value = var.subscription_id
    },
    {
      name  = "azureDNS.resourceGroupName"
      value = var.dns_zone_resource_group
    },
    {
      name  = "azureDNS.hostedZoneName"
      value = var.dns_zone_name
    },
    {
      name  = "azureDNS.managedIdentity.clientID"
      value = var.identity_client_id
    }
  ]

  depends_on = [
    helm_release.cert_manager
  ]
}
