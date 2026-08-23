# Módulos compartilhados vs. versões de provider

`src/cluster`, `src/nodepool` e `src/helm/modules/*` são compartilhados pelos 5
exemplos, mas cada exemplo pina uma versão diferente de provider. **Editar um
módulo compartilhado afeta todos os exemplos.**

| Exemplo | azurerm | helm | Estado |
|---|---|---|---|
| `cluster_argocd_ingress_istio` | **>= 5.0** | **>= 3.0** | migração em andamento |
| `cluster_argocd_ingress_azure` | >= 4.0 | >= 3.0 | migração parcial anterior |
| `cluster_argocd_ingress_nginx` | >= 3.0 | (sem pin) | legado |
| `cluster_one_nodepool` | >= 3.0 | — | legado |
| `cluster_two_nodepools` | >= 3.0 | — | legado (usa `src/nodepool`) |

## Estratégia acordada

Migrar **um exemplo por vez**, começando por `cluster_argocd_ingress_istio`. Os
demais permanecem em versões antigas (e podem ficar temporariamente quebrados
quanto aos módulos compartilhados) até que o exemplo em foco seja provisionado
de verdade, validado e destruído.

## Incompatibilidades conhecidas

- `node_provisioning_profile` (`src/cluster/main.tf`) só existe no azurerm v5 →
  quebra os exemplos v3/v4.
- Renomeações no `src/nodepool` (`auto_scaling_enabled`, `node_public_ip_enabled`,
  `host_encryption_enabled`) são v4+ → quebram exemplos v3.
- Sintaxe helm `set = [...]` (lista) é v3; `set {...}` (bloco) é v2. Não misturar
  no mesmo módulo.
- helm v3: `provider "helm"` usa `kubernetes = {...}` (atributo), não bloco.
- `azurerm_federated_identity_credential` no v5 usa `user_assigned_identity_id`;
  não aceita `parent_id` nem `resource_group_name`.
- Labels de pod via helm `set` precisam `type = "string"` (ex.:
  `azure.workload.identity/use = "true"`), senão o helm infere boolean e o k8s
  rejeita o label.

## Quebras esperadas (não são regressão)

- `cluster_argocd_ingress_azure` e `cluster_argocd_ingress_nginx` falham em
  `terraform validate`: `identity_client_id` virou obrigatório no módulo
  `external-dns`, mas esses exemplos ainda passam `client_id`/`client_secret`
  pré-Workload-Identity.
- Chart `ingress-azure` removido — afeta só o exemplo azure.
