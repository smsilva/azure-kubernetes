# Grupo AD de acesso ao ArgoCD exclusivo por cluster

- **Data:** 2026-08-23
- **Escopo:** `examples/cluster_argocd_ingress_istio` apenas (estratégia de
  migração acordada: um exemplo por vez). Os demais 4 exemplos continuam no
  modelo atual (grupo `aks-contributor` compartilhado, hardcoded).
- **Motivação:** confirmar que o app registration do ArgoCD (redirect URI)
  já é exclusivo por cluster, e substituir o grupo de contributors
  compartilhado (`aks-contributor`, mesmo `object_id` reusado por todos os
  exemplos) por um grupo Azure AD que nasce e morre junto com o cluster,
  com opção de agregar grupos AD pré-existentes.

## Contexto atual

- `src/active-directory/app-registration/main.tf` cria um `azuread_application`
  cujo nome (`var.name`) e `redirect_uris`
  (`https://argocd.<dns_zone>/auth/callback`,
  `https://<name>.<dns_zone>/auth/callback`) incorporam
  `local.argocd_host_base_name` = `local.cname_record_argocd`, derivado de
  `local.cluster_random_id` (`random_string.id.result`, único por apply).
  **Confirmado:** o callback já é exclusivo por cluster — sem colisão entre
  clusters mesmo compartilhando a mesma DNS zone. Nenhuma mudança necessária
  aqui.
- `src/helm/modules/argo-cd/templates/rbac-config.yaml` já suporta dois
  grupos parametrizados: `server_rbac_config_group_administrators` →
  `role:admin` (acesso total) e `server_rbac_config_group_contributors` →
  `role:app-contributor` (sync/get/delete/restart em `default/*`) +
  `role:readonly`. `policy.default: role:empty` já nega por padrão qualquer
  usuário fora dos dois grupos.
- `examples/common/variables.tf` hardcoda:
  - `cluster_administrators_ids = ["...d0e1"]  # aks-administrator` — grupo
    **compartilhado** entre todos os exemplos, usado tanto em
    `admin_group_object_ids` do AKS (`src/cluster`) quanto em
    `argocd_administrators_ids`.
  - `argocd_contributors_ids = ["...d79f"]  # aks-contributor` — também
    **compartilhado** entre todos os exemplos.
- ArgoCD autentica via OIDC direto contra o tenant Azure AD (issuer
  `login.microsoftonline.com/<tenant>/v2.0`), com claim `groups` no ID
  token — **não depende** de `admin_group_object_ids` do AKS. Login no
  ArgoCD e RBAC do Kubernetes são autorizações independentes.

## Decisões (aprovadas em brainstorming)

1. **Grupo `aks-admin` continua compartilhado**, sem mudança. Faz sentido
   como papel organizacional (acesso total em qualquer cluster), não por
   cluster. `cluster_administrators_ids` / `argocd_administrators_ids`
   permanecem como estão.
2. **Novo módulo Terraform** `src/active-directory/cluster-access-group`,
   instanciado uma vez pelo exemplo istio, cria um `azuread_group`
   exclusivo do cluster (nome derivado de `local.cluster_random_id`, ex.:
   `aks-cluster-users-<random_id>`), `security_enabled = true`, owner = SP
   do Terraform (`data.azuread_client_config.current.object_id`, mesmo
   padrão do `app-registration`).
3. **Parâmetro opcional `existing_member_group_ids`** (`list(string)`,
   default `[]`): para cada id informado, o módulo cria um
   `azuread_group_member` aninhando o grupo pré-existente como membro do
   grupo novo. Se vazio, o grupo novo fica sem membros extras (adicionados
   manualmente depois). Azure AD propaga a claim `groups` transitivamente,
   então membros de grupos aninhados também autenticam com o RBAC do grupo
   novo, sem mudança em `sso.yaml`/`rbac-config.yaml`.
4. **Output** `object_id` do módulo substitui o valor hardcoded de
   `argocd_contributors_ids` na instanciação do `argo-cd` helm module
   dentro de `examples/cluster_argocd_ingress_istio/main.tf` — o grupo novo
   passa a ser o único contributor daquele cluster, com `role:app-contributor`
   (sync/restart, sem delete — nível de privilégio já existente no
   rbac-config, sem mudança de policy).
5. **Lifecycle**: o grupo novo é destruído junto com o cluster (`terraform
   destroy`). Grupos pré-existentes aninhados via `existing_member_group_ids`
   **não são afetados** — só o vínculo de membership (`azuread_group_member`)
   é removido.
6. **Fora de escopo**: RBAC por ArgoCD `AppProject` (opção descartada em
   favor do nível "contributor" simples, já suportado); grupo `aks-admin`
   por cluster (descartado, ver decisão 1).

## Permissão adicional necessária no Service Principal

Criar `azuread_group`/`azuread_group_member` via Terraform exige que o SP
tenha permissão de escrita em grupos no Azure AD — hoje o SP só tem
`User Access Administrator` na subscription (role Azure RBAC, escopo de
recursos Azure) e permissões de Microsoft Graph para `azuread_application`
(app registration). Grupos são um recurso de diretório separado; será
necessário conceder ao SP a role de diretório **Groups Administrator** (ou
a permissão de aplicativo do Microsoft Graph `Group.ReadWrite.All` com
admin consent) — análogo ao papel de `scripts/sp-grant-user-access-administrator`,
mas para o diretório Azure AD em vez da subscription Azure. O mecanismo
exato (role de diretório via `az rest`/Microsoft Graph API vs. permissão de
aplicativo) fica para a fase de implementação.

## Documentação a atualizar

- **`README.md` (raiz)**: tabela de scripts (linha ~64, ao lado de
  `sp-grant-aks-cluster-admin`) ganha uma entrada para o novo script/role
  necessário para criar grupos; texto próximo à linha 113 (que hoje só fala
  do grupo `aks-administrator`) ganha uma nota sobre o grupo de contributors
  ser criado por cluster.
- **`examples/cluster_argocd_ingress_istio/README.md`**: tabela de
  variáveis (linha ~158) — `argocd_contributors_ids` deixa de vir de
  `../common/variables.tf` (só `argocd_administrators_ids` continua vindo
  de lá); documentar o novo módulo `cluster-access-group` e o parâmetro
  `existing_member_group_ids`.

## Testes / validação

- `terraform init -backend=false && terraform validate` no exemplo istio
  (sem credenciais).
- Validação real no próximo provisionamento do exemplo (já em andamento de
  migração, conforme estratégia acordada no `CLAUDE.md`):
  - Conta membro do grupo `aks-cluster-users-*` consegue logar no ArgoCD,
    ver e sincronizar Applications, mas não consegue deletar.
  - Conta membro de um grupo pré-existente informado em
    `existing_member_group_ids` tem o mesmo comportamento acima (herda via
    nesting).
  - Conta fora de qualquer grupo cai em `role:empty` (nega tudo).
  - Conta do grupo `aks-admin` continua com acesso total, sem mudança.
