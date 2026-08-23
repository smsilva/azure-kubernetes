# Workload Identity: external-secrets and external-dns

`src/active-directory/workload-identity` is the reusable module (user-assigned
MI + federated credential); it requires the `oidc_issuer_url` output from
`src/cluster`.

## external-secrets (ESO 2.9.0)

- Authenticates to the Key Vault through Workload Identity (no client_secret in
  the cluster): annotate the `external-secrets` SA with
  `azure.workload.identity/client-id` and use `authType: WorkloadIdentity` +
  `serviceAccountRef` in the `ClusterSecretStore`.
- ESO 2.9.0 serves the CRD only at `external-secrets.io/v1` (v1beta1 and
  v1alpha1 are `served=false`, `unsafeServeV1Beta1: false`). Use
  `apiVersion: external-secrets.io/v1` in **every** `ExternalSecret` — the
  schema is identical across versions. Old manifests fail on apply with
  `ExternalSecret "" not found`.

## external-dns

- The azure provider picks its auth mode from the flag in `azure.json` (the
  `azure-config-file` secret of the `external-dns-config` chart):
  `useWorkloadIdentityExtension: true` (federated MI) vs.
  `useManagedIdentityExtension: true` (kubelet SP). Do not pass
  `aadClientId`/`aadClientSecret` in Workload Identity mode — the client-id
  comes from the SA annotation.
- The federated MI needs `DNS Zone Contributor` **on the DNS Zone**, not on the
  resource group.
- The old `azurerm_role_assignment.kubelet_contributor_on_dns_zone` was removed
  (2026-08-22). **Do not reintroduce it**: the kubelet identity is reachable
  over IMDS by any pod on the node, which would grant DNS zone writes to a
  compromised workload.
- To prove **write** permission (the logs only say `All records are already up
  to date`, which proves reads): create an `ExternalName` `Service` with the
  `external-dns.alpha.kubernetes.io/hostname` annotation on a throwaway host,
  check the CNAME + ownership TXT in the zone, then delete the Service.
- The `discarding CNAME record` warning when an A and a CNAME share a host is
  benign.
