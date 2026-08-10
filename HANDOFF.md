# HANDOFF

## Why

Atualizar providers e charts do exemplo `examples/cluster_argocd_ingress_istio` (azurerm v5, azuread v3, helm v3, AKS 1.34.9). Estratégia acordada: migrar **um exemplo por vez**, religando cada `install_*` isoladamente, provisionando de verdade, validando no cluster e destruindo antes de seguir. Módulos em `src/` são compartilhados pelos 5 exemplos — editá-los quebra os que ainda estão em provider antigo (aceito temporariamente até migrar cada um). Ver `CLAUDE.md` para o mapa de versões por exemplo e os gotchas.

## In Progress

cert-manager e external-secrets religados e validados no cluster; external-secrets migrado para Workload Identity. Ambiente **destruído** (`terraform destroy`) para não gerar custo — nenhum RG `wasp-sandbox` remanescente. Toggles `install_cert_manager`, `install_external_secrets` e `install_external_dns` estão `true`; o resto `false`.

external-dns **migrado para Workload Identity no código** (não validado no cluster — ambiente ainda destruído). Mudanças: chart `external-dns-config` usa `useWorkloadIdentityExtension` (era `useManagedIdentityExtension`); módulo `external-dns` recebe `identity_client_id` e anota SA + pod label (padrão ESO); exemplo istio ganhou `module.external_dns_workload_identity` + `azurerm_role_assignment.external_dns_contributor_on_dns_zone` (DNS Zone Contributor na MI federada). `terraform validate` OK.

Próximo passo pretendido: reconstruir o cluster (`apply`), validar registros DNS criados pelo external-dns via Workload Identity, depois religar ingress-istio.

## Open Questions / Hypotheses

- external-dns via Workload Identity: **feito no código** (role `DNS Zone Contributor` na MI federada; chart 1.21.1 confirmado aceitando `serviceAccount.annotations` + `podLabels`). Falta validar no cluster. O `azurerm_role_assignment.kubelet_contributor_on_dns_zone` (em `examples/common/variables.tf`, compartilhado, sem `count`) foi mantido intacto — fica ocioso neste exemplo mas continua aplicando; remover só quando migrar os demais exemplos.
- Charts com bump commitado mas NÃO validados: argo-cd 10.3.2, external-dns 1.21.1, ingress-nginx 4.15.1. Bumps grandes (argo-cd 7→10) podem exigir ajuste de `values`/templates/CRDs ao religar.
- ArgoCD (chart 10.3.2): revisar mudanças de configmap/RBAC/CRDs e o SSO via azuread (`instance.client_id`) ao religar.

## Known Broken

- **Outros 4 exemplos** (`cluster_argocd_ingress_azure`, `_nginx`, `cluster_one_nodepool`, `cluster_two_nodepools`) — *intencional*: os módulos compartilhados já estão em azurerm v5/helm v3 e quebram esses exemplos até migrá-los. `two_nodepools` usa `src/nodepool` (já v4+). Ajustes por exemplo: subir provider para v5, adicionar `node_provisioning_profile`, `application_id`→`client_id`, pin helm v3.
- **Chart `ingress-azure` removido** — *inesperado*: `helm fetch` não retornou o chart na versão buscada e o diretório foi apagado. Usado só pelo exemplo azure. Ao migrar aquele exemplo, refazer fetch de `oci://mcr.microsoft.com/azure-application-gateway/charts/ingress-azure` (ver README) ou remover em definitivo.

## How to Resume

```bash
cd examples/cluster_argocd_ingress_istio
terraform init
terraform apply -auto-approve   # reconstrói cluster + cert-manager + external-secrets (toggles já true)
az aks get-credentials --resource-group <rg> --name <cluster> --admin --overwrite-existing
kubectl get clustersecretstore   # esperado: Valid
```

## Next Steps

1. Reconstruir cluster (`apply`) e validar external-dns via Workload Identity criando registros DNS (código já commitado). Charts locais só mudam template → talvez `-replace='module.external_dns[0].helm_release.external_dns_config'` (gotcha CLAUDE.md).
2. Religar ingress-istio (charts istio 1.30.3 já no repo); validar Gateway/certificados; commit.
3. Religar argocd (chart 10.3.2) + httpbin; validar UI/SSO; commit.
4. Religar app-of-apps-infra; validar; commit.
5. Provisionar a stack completa, validar end-to-end e **destruir**.
6. Só então migrar os outros 4 exemplos (ver Known Broken).

> Before trusting anything time-sensitive above, run `git status`, `git diff`, and `git log` against the base branch.
