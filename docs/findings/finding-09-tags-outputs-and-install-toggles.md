# #9 — sem tags, `install_*` como `locals`, `outputs.tf` incompleto

- **Severidade:** 🟡 baixa
- **Onde:** `examples/cluster_argocd_ingress_istio/main.tf`, `outputs.tf`
- **Status:** aberto

Três lacunas de DX/higiene, sem risco de segurança, agrupadas por serem do
mesmo tipo (dívida de qualidade em vez de defeito funcional):

## Zero tags em RG/cluster

Nem o `azurerm_resource_group` nem o `azurerm_kubernetes_cluster` (via
`src/cluster`) recebem `tags`. Sem tags, não dá para filtrar custo por
projeto/ambiente/dono no Azure Cost Management, nem aplicar políticas de
governança baseadas em tag. Correção: adicionar um `local.tags` padrão
(`project`, `environment`, `managed-by = "terraform"`) e propagar para os
recursos que aceitam `tags`.

## `install_*` são `locals`, não `variable`

Os toggles que ligam/desligam módulos (`install_cert_manager`,
`install_external_dns`, `install_ingress_istio`, etc.) estão definidos como
`locals` fixos no `main.tf`, então não dá para ligar/desligar um módulo via
`-var` ou `.tfvars` sem editar o `.tf`. Isso dificulta usar o mesmo exemplo
para cenários diferentes (ex.: CI rodando só `terraform validate` sem
provisionar nada, ou um ambiente de teste que não precisa de `httpbin`).
Correção: promover para `variable "install_cert_manager" { type = bool,
default = true }` etc., mantendo o default atual.

## `outputs.tf` só devolve `url_gateway`

Depois de um `apply`, não há como pegar o nome do cluster, o resource group,
a URL do ArgoCD ou do httpbin sem ler o state manualmente ou voltar ao
`locals`. Correção: adicionar outputs para `cluster_name`,
`cluster_resource_group_name`, `url_argocd`, `url_httpbin` (quando os
módulos correspondentes estiverem ligados).

## Como validar

Só `terraform validate`/`plan` — nenhuma das três mudanças altera
comportamento de infraestrutura existente (tags e outputs não forçam
recreate; a variável nova mantém o mesmo default do local atual).
