# #5 — providers `kubernetes`/`helm` usam `kube_admin_config`

- **Severidade:** 🟠 média
- **Onde:** `examples/cluster_argocd_ingress_istio/provider.tf:30,38`
- **Status:** RESOLVIDO (2026-08-23)

## O problema

```hcl
provider "kubernetes" {
  host                   = module.aks.instance.kube_admin_config.0.host
  token                  = module.aks.instance.kube_admin_config.0.password
  cluster_ca_certificate = base64decode(module.aks.instance.kube_admin_config.0.cluster_ca_certificate)
}

provider "helm" {
  kubernetes = {
    host                   = module.aks.instance.kube_admin_config.0.host
    token                  = module.aks.instance.kube_admin_config.0.password
    cluster_ca_certificate = base64decode(module.aks.instance.kube_admin_config.0.cluster_ca_certificate)
  }
}
```

`kube_admin_config` é a credencial de **admin local** do cluster (o
equivalente a `az aks get-credentials --admin`). Duas consequências:

1. **Bypassa o Azure RBAC do cluster.** O exemplo já usa
   `azure_rbac_enabled = true` + `admin_group_object_ids` (grupo
   `aks-administrator`) — o controle de acesso "correto" é via Entra ID. Usar
   a credencial admin local ignora esse controle inteiramente: ela sempre tem
   cluster-admin, independente de quem está no grupo.
2. **Grava a credencial admin em texto claro no state.** `kube_admin_config.0.password`
   é o client key/token de admin do cluster — qualquer coisa com acesso de
   leitura ao state (local ou remoto) tem, de fato, acesso admin ao cluster.

## A alternativa

Trocar `kube_admin_config` por `kube_config` (credencial não-admin, resolvida
via Azure AD) combinado com o plugin `exec` do provider, usando `kubelogin`:

```hcl
provider "kubernetes" {
  host                   = module.aks.instance.kube_config.0.host
  cluster_ca_certificate = base64decode(module.aks.instance.kube_config.0.cluster_ca_certificate)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "kubelogin"
    args        = ["get-token", "--login", "azurecli", "--server-id", "6dae42f8-4368-4678-94ff-3960e28e3630"]
  }
}
```

`--login azurecli` é o modo de login que unifica local e CI sem precisar de
`if` de ambiente no `provider.tf`: localmente usa a sessão `az login` do
usuário; em CI usa a identidade federada de `azure/login@v2` (já configurada,
ver `.github/workflows/azure-oidc-federation.yml`). O `provider "helm"` segue
o mesmo padrão via o atributo `kubernetes = { exec = {...} }`.

Isso faz o Terraform (e quem quer que rode o `apply`) passar pelo mesmo
caminho de autorização Azure RBAC que qualquer outro acesso ao cluster — e
tira a credencial admin do state.

## Pré-requisitos antes de aplicar

- `kubelogin` instalado na máquina/runner (já usado no workflow de CI e
  documentado em `scripts/`).
- O **Service Principal do Terraform** precisa estar num grupo/role com
  `Azure Kubernetes Service RBAC Cluster Admin` (ou equivalente) — **não
  verificado ainda** se o SP atual (`terraform-wasp-sandbox`) atende. Sem
  isso, o próprio Terraform perde acesso ao cluster para gerenciar os
  recursos `kubernetes_*`/`helm_release` depois da troca.

## Como validar

1. Confirmar a role do SP (`az role assignment list --assignee <client-id>`
   ou membership de grupo com a role RBAC do cluster).
2. Provisionar um cluster (o atual foi destruído).
3. Aplicar a troca e rodar `terraform plan`/`apply` até o fim — se o SP não
   tiver a role certa, o erro aparece logo nos primeiros recursos
   `kubernetes_namespace_v1`/`helm_release`.
4. Confirmar que `kube_admin_config`/senha não aparecem mais em
   `terraform show`/no state.

## Resolução (2026-08-23)

Aplicado exatamente como proposto acima, com `--login azurecli` (não `spn`):
o modo `spn` exigiria `ARM_CLIENT_SECRET`, que não existe no workflow de CI
(`azure-oidc-federation.yml` usa `ARM_USE_OIDC=true` sem secret). `azurecli`
reaproveita a sessão já autenticada — `az login` do usuário localmente,
`azure/login@v2` federado em CI — sem `if` de ambiente no `provider.tf`.

Validação contra o cluster vivo (`wasp-sandbox-0a2oc`):
- SP do Terraform (`ARM_CLIENT_ID`) confirmado membro do grupo
  `d5075d0a-3704-4ed9-ad62-dc8068c7d0e1` (`adminGroupObjectIDs` do cluster,
  `enableAzureRbac: true`) — não tinha role assignment dedicada, mas a
  membership no grupo AAD-admin do AKS já concede acesso equivalente a
  cluster-admin via Azure RBAC, sem necessidade de
  `Azure Kubernetes Service RBAC Cluster Admin` explícita.
- Usuário `az login` local (`smsilva@gmail.com`) também confirmado membro do
  mesmo grupo — `--login azurecli` funciona local e em CI sem diferença de
  privilégio.
- `kubectl get nodes` via `kubelogin convert-kubeconfig -l spn` (teste manual
  fora do Terraform) e `terraform plan` (via `exec`/`azurecli`) ambos OK.
- `terraform plan` contra o cluster vivo → `No changes` (todos os
  `helm_release`/recursos `kubernetes_*` lidos com sucesso via a nova auth).
- `kube_admin_config`/senha continuam no state como atributo do recurso
  `azurerm_kubernetes_cluster` (a Azure sempre expõe isso, a menos que
  `disable_local_accounts = true`), mas os providers `kubernetes`/`helm` não
  fazem mais referência a eles — a superfície de uso foi eliminada, não o
  atributo do recurso em si.
