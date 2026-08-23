# Terraform / Azure

## Permissões do SP

- Precisa de `User Access Administrator` (não só `Contributor`) para criar os
  `azurerm_role_assignment` dos exemplos → `scripts/sp-grant-user-access-administrator --client-id <id>`.
- Key Vault `waspfoundation*` usa access policy (RBAC desabilitado) → dar acesso a
  identidades via `azurerm_key_vault_access_policy`, não role assignment.

## Providers `kubernetes`/`helm` do exemplo istio

Usam `kube_config` + `exec`/`kubelogin --login azurecli` (não `kube_admin_config`).
Membership no grupo `admin_group_object_ids` do cluster (com `azure_rbac_enabled = true`)
já concede acesso equivalente a cluster-admin via Azure RBAC — não precisa de role
assignment dedicada.

`--login azurecli` e não `spn`: `spn` exige `ARM_CLIENT_SECRET`, ausente no CI que usa
OIDC federado (`ARM_USE_OIDC=true`); `azurecli` reaproveita a sessão já autenticada
(local: `az login`; CI: `azure/login@v2`) sem `if` de ambiente. O `server-id` do exec
plugin é o app ID fixo do AKS AAD Server: `6dae42f8-4368-4678-94ff-3960e28e3630`.

Atenção: `kube_admin_config`/senha continuam aparecendo no `terraform state` — é atributo
do `azurerm_kubernetes_cluster`, exposto sempre que `disable_local_accounts != true`. A
troca elimina o *uso* pelos providers, não a presença no state.

Acesso kubectl sem `kubelogin`:
`az aks get-credentials --resource-group <rg> --name <cluster> --admin --overwrite-existing`.

## Tags no RG + cluster na mesma apply forçam replace

`src/cluster` lê `data.azurerm_resource_group.default.location`. Enquanto o RG tem
mudança pendente esse data source fica "known after apply", tornando `location` (campo
`ForceNew` do AKS) desconhecido — dispara `-/+` no cluster e cascateia para os providers
`kubernetes`/`helm`, recriando todos os helm releases.

Mitigação: aplicar em duas etapas com `-target` (RG primeiro, sozinho; só depois o módulo
do cluster) — o AKS conclui como `update in-place`. Ainda sobra 1 `azurerm_role_assignment`
recriado (mesmo efeito, escala menor).

## Warning benigno no destroy

CRDs do cert-manager (e do Istio) são mantidos pela `resource-policy: keep` no
`helm uninstall`. Como o cluster inteiro é destruído junto, somem com o control plane —
nada fica órfão no Azure.

## `scripts/update-local-helm-charts`

NÃO é só checagem: faz `rm -rf` + `helm fetch --untar` e **substitui** os charts locais
quando a versão remota difere. Rodar só quando quiser de fato atualizar.

O helm provider não detecta mudança quando só o **conteúdo do chart local** muda (mesmos
`values`/`set`). Forçar com `terraform apply -replace='module.<mod>[0].helm_release.<release>'`
— exceto no `istio_gateway`, ver `docs/reference/istio-tls-ingress.md`.

## CI: acesso SSH a módulos privados (`git::ssh`)

- `network.tf`/`secrets.tf` puxam `vnet` e `argocd_app_registration_password` de
  `git::ssh://git@github.com/smsilva/{azure-network,azure-key-vault}.git` — repos privados,
  sem acesso por padrão num runner GitHub Actions.
- GitHub rejeita a mesma chave pública como deploy key em mais de um repositório
  (`422 key is already in use`). Solução: uma chave por repo módulo
  (`scripts/github-actions-configure-ssh-deploy-key`), mapeada por alias de host em
  `~/.ssh/config` + `git config url."ssh://git@github.com-<repo>/...".insteadOf "ssh://git@github.com/..."`.
- O `insteadOf` precisa casar a URL **exata**: o detector de módulo git do Terraform gera
  `ssh://git@github.com/owner/repo` (URL completa), não a forma SCP-like
  `git@github.com:owner/repo`. Usar a forma errada faz o `insteadOf` nunca casar,
  silenciosamente (o clone cai na identidade default).
- `local.arm_client_secret`/`module "variables"` (`src/variables`) só são usados por
  `cluster_argocd_ingress_azure` e `cluster_argocd_ingress_nginx` — vivem em arquivos
  próprios desses exemplos, não em `examples/common/variables.tf` (istio não paga o custo
  do `data "external"` a cada plan).
