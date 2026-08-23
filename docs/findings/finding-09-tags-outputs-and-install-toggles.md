# #9 — sem tags, `install_*` como `locals`, `outputs.tf` incompleto

- **Severidade:** 🟡 baixa
- **Onde:** `examples/cluster_argocd_ingress_istio/main.tf`, `outputs.tf`
- **Status:** RESOLVIDO (tags aplicadas; toggles mantidos como `locals` por
  decisão do usuário; outputs completados)

Três lacunas de DX/higiene, sem risco de segurança, agrupadas por serem do
mesmo tipo (dívida de qualidade em vez de defeito funcional):

## Zero tags em RG/cluster — RESOLVIDO

Adicionado `local.tags` (`project`, `environment`, `example`, `managed-by =
"terraform"`, `owner`) no exemplo istio, aplicado em `azurerm_resource_group`
e propagado ao `azurerm_kubernetes_cluster` via novo `var.tags` (opcional,
default `{}`) em `src/cluster` — aditivo, não quebra os outros exemplos.

**Gotcha descoberto na validação contra `wasp-sandbox-0a2oc`:** tagear o
`azurerm_resource_group` e o `azurerm_kubernetes_cluster` na **mesma** apply
força replace do cluster inteiro. Causa: `src/cluster` lê
`data.azurerm_resource_group.default.location`; enquanto o RG tem mudança
pendente (mesmo só de `tags`), esse data source fica "known after apply" e
`location` (campo `ForceNew` do AKS) também — disparando `-/+` no cluster e
cascateando para os providers `kubernetes`/`helm` (cujo `host`/`kube_config`
vêm do mesmo recurso), gerando um plano de recriar todos os helm releases.
**Mitigação:** aplicar em duas etapas separadas — 1) `-target=azurerm_resource_group.default`
sozinho (RG convergido, sem drift pendente), 2) só então `-target=module.aks`
— assim o AKS conclui como `update in-place` (não replace). Mesmo nesse
caminho, sobrou um `azurerm_role_assignment.kubelet_contributor_on_cluster_infrastructure_resource_group`
recriado (escopo lido via `data.azurerm_resource_group.cluster_infrastructure`,
mesmo efeito em escala menor) — replace rápido, sem downtime observado.
Validado: `terraform plan` → `No changes` depois das duas applies; os três
hosts (`gateway`/`argocd`/`httpbin`) seguiram servindo HTTPS 200 durante todo
o processo.

## `install_*` são `locals`, não `variable` — MANTIDO COMO ESTÁ

Decisão do usuário: não promover para `variable` por ora. Os toggles
continuam como `locals` fixos no `main.tf`.

## `outputs.tf` só devolvia `url_gateway` — RESOLVIDO

Adicionados `cluster_name`, `cluster_resource_group_name`, `url_argocd`,
`url_httpbin` em `outputs.tf`, seguindo o mesmo padrão de
`"<host>.${local.cluster_random_id}.${local.dns_zone}"` já usado por
`url_gateway`. Validado ao vivo contra `wasp-sandbox-0a2oc`: `terraform plan`
mostrou só os 4 outputs novos (`0 to add/change/destroy` de recursos);
`terraform apply` do plano gravou os outputs no state sem tocar
infraestrutura.

## Como validar

Tags: `terraform validate`/`plan` mostram a mudança certa, mas **aplicar
exige duas etapas** (RG, depois AKS — ver gotcha acima) para não forçar
replace do cluster. Outputs: `terraform plan` mostra só `Changes to Outputs`
(nenhum recurso); `terraform apply` do plano é seguro mesmo contra o cluster
vivo.
