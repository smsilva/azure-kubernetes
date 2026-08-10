# azure-kubernetes

Repositório de módulos Terraform para provisionar AKS com stack GitOps (ArgoCD) e opções de ingress (Istio, NGINX, Application Gateway).

## Estrutura

- `src/` — módulos Terraform reutilizáveis (compartilhados entre exemplos)
  - `src/cluster` — `azurerm_kubernetes_cluster` + role assignments
  - `src/nodepool` — `azurerm_kubernetes_cluster_node_pool` adicional
  - `src/active-directory/app-registration` — `azuread_application` para SSO do ArgoCD
  - `src/application-gateway` — ingress via Azure Application Gateway
  - `src/helm/modules/*` — wrappers `helm_release` (cert-manager, external-secrets, external-dns, ingress-istio, ingress-nginx, ingress-azure, httpbin, argo-cd, app-of-apps-infra)
  - `src/helm/charts/*` — charts locais (vendored via `helm fetch`)
- `examples/` — 5 exemplos que consomem os módulos de `src/`
- `examples/common/` — arquivos compartilhados por symlink (`variables.tf`, `secrets.tf`, `network.tf`)
- `scripts/` — utilitários (ver `scripts/update-local-helm-charts` e `scripts/update-local-helm-charts-istio`)

## ⚠️ Módulos compartilhados vs. versões de provider por exemplo

`src/cluster`, `src/nodepool` e `src/helm/modules/*` são **compartilhados** pelos 5 exemplos, mas cada exemplo pina uma versão diferente de provider. **Editar um módulo compartilhado afeta todos os exemplos.**

| Exemplo | azurerm | helm | Estado |
|---|---|---|---|
| `cluster_argocd_ingress_istio` | **>= 5.0** | **>= 3.0** | migração em andamento |
| `cluster_argocd_ingress_azure` | >= 4.0 | >= 3.0 | migração parcial anterior |
| `cluster_argocd_ingress_nginx` | >= 3.0 | (sem pin) | legado |
| `cluster_one_nodepool` | >= 3.0 | — | legado |
| `cluster_two_nodepools` | >= 3.0 | — | legado (usa `src/nodepool`) |

**Incompatibilidades conhecidas ao migrar módulos compartilhados:**
- `node_provisioning_profile` (bloco em `src/cluster/main.tf`) **só existe no azurerm v5** → quebra os exemplos v3/v4.
- Renomeações no `src/nodepool` (`auto_scaling_enabled`, `node_public_ip_enabled`, `host_encryption_enabled`) são **v4+** → quebram exemplos v3.
- Sintaxe helm `set = [...]` (lista de objetos) é **v3**; `set {...}` (bloco) é **v2**. Não misturar no mesmo módulo.

Ver `HANDOFF.md` para o estado detalhado da migração e pendências.

## Estratégia de migração (acordada)

Migrar **um exemplo por vez**, começando por `cluster_argocd_ingress_istio`. Os demais exemplos permanecem em versões antigas (e podem ficar temporariamente quebrados quanto aos módulos compartilhados) até que o exemplo em foco seja **provisionado de verdade, validado e destruído**. Só então migrar os próximos.

## Convenções

- Rodar `terraform fmt` antes de commitar.
- Validar com `terraform init -backend=false && terraform validate` (não requer credenciais).
- `.terraform.lock.hcl` NÃO é versionado (ver `.gitignore`).
