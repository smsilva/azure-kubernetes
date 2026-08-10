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
- No helm provider v3, o `provider "helm"` usa `kubernetes = {...}` (atributo), não `kubernetes {...}` (bloco).
- `azurerm_federated_identity_credential` no v5 usa `user_assigned_identity_id`; NÃO aceita `parent_id` nem `resource_group_name`.
- Labels de pod via helm `set` precisam `type = "string"` (ex.: `azure.workload.identity/use = "true"`), senão o helm infere boolean e o k8s rejeita o label.

## Gotchas operacionais

- `scripts/update-local-helm-charts` NÃO é só checagem: faz `rm -rf` + `helm fetch --untar` e **substitui** os charts locais quando a versão remota difere. Rodar só quando quiser de fato atualizar.
- O helm provider não detecta mudança quando só o **conteúdo do chart local** muda (mesmos `values`/`set`). Forçar com `terraform apply -replace='module.<mod>[0].helm_release.<release>'`.
- Acesso kubectl sem `kubelogin`: usar admin config → `az aks get-credentials --resource-group <rg> --name <cluster> --admin --overwrite-existing`.
- O SP do Terraform precisa de `User Access Administrator` (não só `Contributor`) para criar os `azurerm_role_assignment` dos exemplos; conceder via `scripts/sp-grant-user-access-administrator --client-id <id>`.
- Key Vault `waspfoundation*` usa access policy (RBAC desabilitado) → dar acesso a identidades via `azurerm_key_vault_access_policy`, não role assignment.

## external-secrets (ESO 2.9.0)

- Autentica no Key Vault via **Workload Identity** (sem client_secret no cluster): anota o SA `external-secrets` com `azure.workload.identity/client-id` e usa `authType: WorkloadIdentity` + `serviceAccountRef` no `ClusterSecretStore`.
- ESO 2.9.0 serve o CRD apenas em `external-secrets.io/v1` (v1beta1 `served=false`); usar `apiVersion: external-secrets.io/v1` nos manifests do `external-secrets-config`.
- `src/active-directory/workload-identity` é o módulo reutilizável (user-assigned MI + federated credential); requer o output `oidc_issuer_url` de `src/cluster`.

Ver `HANDOFF.md` para o estado detalhado da migração e pendências.

## Estratégia de migração (acordada)

Migrar **um exemplo por vez**, começando por `cluster_argocd_ingress_istio`. Os demais exemplos permanecem em versões antigas (e podem ficar temporariamente quebrados quanto aos módulos compartilhados) até que o exemplo em foco seja **provisionado de verdade, validado e destruído**. Só então migrar os próximos.

## Convenções

- Rodar `terraform fmt` antes de commitar.
- Validar com `terraform init -backend=false && terraform validate` (não requer credenciais).
- `.terraform.lock.hcl` NÃO é versionado (ver `.gitignore`).
