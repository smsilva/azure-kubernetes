# HANDOFF

## Why

Atualizar providers e charts do exemplo `examples/cluster_argocd_ingress_istio` (azurerm v5, azuread v3, helm v3, AKS 1.34.9). Estratégia acordada: migrar **um exemplo por vez**, religando cada `install_*` isoladamente, provisionando de verdade, validando no cluster e destruindo antes de seguir. Módulos em `src/` são compartilhados pelos 5 exemplos — editá-los quebra os que ainda estão em provider antigo (aceito temporariamente até migrar cada um). Ver `CLAUDE.md` para o mapa de versões por exemplo e os gotchas.

## In Progress

cert-manager e external-secrets religados e validados no cluster; external-secrets migrado para Workload Identity. Ambiente **destruído** (`terraform destroy`) para não gerar custo — nenhum RG `wasp-sandbox` remanescente. Toggles `install_cert_manager` e `install_external_secrets` estão `true`; o resto `false`.

Próximo passo pretendido: religar **external-dns** (`install_external_dns = true`) usando Workload Identity com o módulo `src/active-directory/workload-identity` (mesmo padrão do external-secrets), dar acesso à DNS Zone via identidade federada em vez do kubelet SP.

## Open Questions / Hypotheses

- external-dns via Workload Identity: precisa de role na DNS Zone (`DNS Zone Contributor`) para a MI federada, substituindo o `azurerm_role_assignment.kubelet_contributor_on_dns_zone` atual (que usa a kubelet identity). Confirmar se o chart external-dns 1.21.1 aceita `serviceAccount.annotations` + podLabel de workload identity como o ESO.
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

1. Religar external-dns via Workload Identity (`install_external_dns = true` + módulo `workload-identity` + role na DNS Zone); `apply`; validar registros DNS; commit.
2. Religar ingress-istio (charts istio 1.30.3 já no repo); validar Gateway/certificados; commit.
3. Religar argocd (chart 10.3.2) + httpbin; validar UI/SSO; commit.
4. Religar app-of-apps-infra; validar; commit.
5. Provisionar a stack completa, validar end-to-end e **destruir**.
6. Só então migrar os outros 4 exemplos (ver Known Broken).

> Before trusting anything time-sensitive above, run `git status`, `git diff`, and `git log` against the base branch.
