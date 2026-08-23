# Workload Identity: external-secrets e external-dns

`src/active-directory/workload-identity` é o módulo reutilizável (user-assigned MI +
federated credential); requer o output `oidc_issuer_url` de `src/cluster`.

## external-secrets (ESO 2.9.0)

- Autentica no Key Vault via Workload Identity (sem client_secret no cluster): anota o
  SA `external-secrets` com `azure.workload.identity/client-id` e usa
  `authType: WorkloadIdentity` + `serviceAccountRef` no `ClusterSecretStore`.
- ESO 2.9.0 serve o CRD apenas em `external-secrets.io/v1` (v1beta1 e v1alpha1
  `served=false`, `unsafeServeV1Beta1: false`). Usar `apiVersion: external-secrets.io/v1`
  em **todos** os `ExternalSecret` — o schema é idêntico entre versões. Manifests antigos
  falham no apply com `ExternalSecret "" not found`.

## external-dns

- O provider azure escolhe o modo de auth pela flag no `azure.json` (secret
  `azure-config-file` do chart `external-dns-config`): `useWorkloadIdentityExtension: true`
  (MI federada) vs `useManagedIdentityExtension: true` (kubelet SP). Não passar
  `aadClientId`/`aadClientSecret` no modo Workload Identity — o client-id vem da anotação
  do SA.
- A MI federada precisa de `DNS Zone Contributor` **na DNS Zone**, não no RG.
- O antigo `azurerm_role_assignment.kubelet_contributor_on_dns_zone` foi removido
  (2026-08-22). **Não reintroduzir**: a kubelet identity é alcançável via IMDS por
  qualquer pod do nó, o que daria escrita na zona DNS a um workload comprometido.
- Para provar permissão de **escrita** (os logs só dizem `All records are already up to
  date`, o que prova leitura): criar um `Service` `ExternalName` com a annotation
  `external-dns.alpha.kubernetes.io/hostname` num host descartável, conferir CNAME + TXT
  de ownership na zona e deletar o Service.
- Warning `discarding CNAME record` quando há A+CNAME no mesmo host é benigno.
