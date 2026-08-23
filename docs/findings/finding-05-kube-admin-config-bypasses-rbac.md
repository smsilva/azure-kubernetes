# #5 — providers `kubernetes`/`helm` usam `kube_admin_config`

- **Severidade:** 🟠 média
- **Onde:** `examples/cluster_argocd_ingress_istio/provider.tf:30,38`
- **Status:** aberto

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
