# HANDOFF

## Why

Atualizar providers e charts do exemplo `examples/cluster_argocd_ingress_istio` (azurerm v5, azuread v3, helm v3, AKS 1.34.9). Migrar **um exemplo por vez**, religando cada `install_*` isoladamente, provisionando de verdade, validando no cluster e destruindo antes de seguir. Módulos em `src/` são compartilhados pelos 5 exemplos — editá-los quebra os que ainda estão em provider antigo (aceito temporariamente). Ver `CLAUDE.md` para o mapa de versões por exemplo e os gotchas.

## In Progress

external-dns migrado para Workload Identity **no código** (mesmo padrão do external-secrets), não validado no cluster — ambiente segue destruído. Toggles `install_cert_manager`, `install_external_secrets`, `install_external_dns` = `true`; resto `false`. `terraform validate` OK.

Mudanças aplicadas:
- `src/helm/charts/external-dns-config/templates/secret.yaml`: `useWorkloadIdentityExtension: true` (era `useManagedIdentityExtension`).
- `src/helm/modules/external-dns/`: nova var `identity_client_id`; `helm_release.external_dns` anota SA (`azure.workload.identity/client-id`) e pod label (`azure.workload.identity/use`, `type=string`).
- `examples/cluster_argocd_ingress_istio/main.tf`: `module.external_dns_workload_identity` (MI federada, SA `external-dns:external-dns`) + `azurerm_role_assignment.external_dns_contributor_on_dns_zone` (DNS Zone Contributor na MI); external-dns depende desse role.

Próximo passo pretendido: reconstruir cluster (`apply`), validar registros DNS criados via Workload Identity, depois religar ingress-istio.

## Open Questions / Hypotheses

- Charts com bump commitado mas NÃO validados: argo-cd 10.3.2, external-dns 1.21.1, ingress-nginx 4.15.1. Bumps grandes (argo-cd 7→10) podem exigir ajuste de `values`/templates/CRDs ao religar.
- ArgoCD (chart 10.3.2): revisar mudanças de configmap/RBAC/CRDs e o SSO via azuread (`instance.client_id`) ao religar.
- Charts locais só mudam conteúdo de template (mesmos `set`/`values`) → helm provider não detecta diff. Ao religar external-dns talvez seja preciso `-replace='module.external_dns[0].helm_release.external_dns_config'`.

## Known Broken

- **Outros 4 exemplos** (`cluster_argocd_ingress_azure`, `_nginx`, `cluster_one_nodepool`, `cluster_two_nodepools`) — *intencional*: módulos compartilhados já em azurerm v5/helm v3 quebram esses exemplos até migrá-los. `two_nodepools` usa `src/nodepool` (já v4+). Ajustes por exemplo: subir provider p/ v5, adicionar `node_provisioning_profile`, `application_id`→`client_id`, pin helm v3.
- **`azurerm_role_assignment.kubelet_contributor_on_dns_zone`** (em `examples/common/variables.tf`, compartilhado, sem `count`) — *intencional*: mantido intacto para não quebrar outros exemplos; fica ocioso no istio (external-dns agora usa MI federada). Remover só ao migrar os demais.
- **Chart `ingress-azure` removido** — *inesperado*: `helm fetch` não retornou o chart e o diretório foi apagado. Usado só pelo exemplo azure. Ao migrar, refazer fetch de `oci://mcr.microsoft.com/azure-application-gateway/charts/ingress-azure` ou remover em definitivo.

## How to Resume

```bash
cd examples/cluster_argocd_ingress_istio
terraform init
terraform apply -auto-approve   # cluster + cert-manager + external-secrets + external-dns (toggles já true)
az aks get-credentials --resource-group <rg> --name <cluster> --admin --overwrite-existing
kubectl -n external-dns logs deploy/external-dns   # esperado: auth via Workload Identity, sem erro de credencial
```

## Next Steps

1. Reconstruir cluster e validar external-dns via Workload Identity criando registros DNS. Se helm não detectar mudança de chart, forçar com `-replace`.
2. Religar ingress-istio (charts istio 1.30.3 já no repo); validar Gateway/certificados.
3. Religar argocd (chart 10.3.2) + httpbin; validar UI/SSO.
4. Religar app-of-apps-infra; validar.
5. Provisionar a stack completa, validar end-to-end e **destruir**.
6. Só então migrar os outros 4 exemplos (ver Known Broken).

> Before trusting anything time-sensitive above, run `git status`, `git diff`, and `git log` against the base branch.
