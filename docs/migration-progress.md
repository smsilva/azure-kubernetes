# Migration progress log

Histórico de passos concluídos da migração de `examples/cluster_argocd_ingress_istio`
(azurerm v5 / azuread v3 / helm v3 / AKS 1.34.9). Ver `HANDOFF.md` para o estado atual
e os próximos passos.

## 2026-08-10 — external-dns via Workload Identity validado no cluster

- Cluster `wasp-sandbox-02mzu` provisionado (`terraform apply`, 23 recursos). Toggles
  ativos: `install_cert_manager`, `install_external_secrets`, `install_external_dns`.
- external-dns autenticou via **Workload Identity** (confirmado nos logs):
  `Using workload identity extension to retrieve access token for Azure API.`
  seguido de `All records are already up to date` a cada ciclo de 1min, sem erro de
  credencial.
- SA `external-dns/external-dns` anotado com `azure.workload.identity/client-id`
  (`0e6fc972-0a44-436f-b678-b274bd3661f9`); pod com label `azure.workload.identity/use=true`.
- Role `DNS Zone Contributor` da MI federada na DNS Zone `sandbox.wasp.silvios.me`
  funcionando — external-dns lê a zona sem `AuthorizationFailed`.
- Sem registros a criar ainda (ingress-istio desligado, nenhum service/ingress com
  hostname). O ciclo de reconciliação sem erro já prova a cadeia
  SA anotado → token federado → API do Azure DNS.
