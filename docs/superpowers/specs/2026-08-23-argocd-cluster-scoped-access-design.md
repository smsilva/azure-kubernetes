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
   padrão do `app-registration`). O módulo faz **só isso** — cria o grupo e
   exporta o `object_id`. Sem `azuread_group_member`.
3. **Grupos pré-existentes entram na lista de contributors do RBAC, não
   como membros aninhados do grupo novo.** O exemplo concatena:

   ```hcl
   contributors_ids = concat(
     [module.cluster_access_group.object_id],
     local.argocd_extra_contributor_group_ids, # default []
   )
   ```

   `rbac-config.yaml:8-11` já é um `for` sobre
   `server_rbac_config_group_contributors` emitindo um par
   `g, "<id>", role:app-contributor` / `role:readonly` por id, e
   `contributors_ids` já é `list(string)` — então **nenhuma mudança no
   módulo `argo-cd` nem no template** é necessária.

   Motivo da escolha (revisão de 2026-08-23), em vez do nesting
   originalmente aprovado:

   - **Orçamento da claim `groups`**: aninhando, o token de um usuário do
     grupo pré-existente `G` precisa carregar `G` **e** o grupo do cluster
     `N` para o RBAC casar — +1 slot por cluster acessado. Listando direto,
     o RBAC casa em `G`, que já está no token: **+0 slots**,
     independentemente do número de clusters.
   - **Some a dependência da expansão transitiva** da claim `groups` —
     comportamento com ressalvas documentadas (vale para a claim, não para
     provisionamento SCIM). O design passa a depender apenas de "usuário é
     membro de `G`, logo `G` está no token".
   - **Grant auditável em git** (`policy.csv`) em vez de escondido na
     membership do Azure AD.

   Trade-off aceito: alterar quais grupos têm acesso passa a exigir
   `terraform apply` (o id atravessa `policy.csv` → values do helm →
   `helm_release`), em vez de uma edição de membership no portal com efeito
   imediato.

   Esse trade-off é **desejado**, não apenas tolerado: o disparo do
   Terraform deve migrar para GitOps, e nesse modelo conceder acesso a um
   time passa a ser um pull request revisado e rastreável — o controle que
   se quer para uma concessão de privilégio, e que a edição de membership
   no portal do Azure AD não oferece.

   O grupo do cluster (`N`) continua existindo e sendo contributor — serve
   para adicionar **usuários individuais** àquele cluster e como âncora de
   identidade exclusiva do cluster.
4. **Nível de privilégio**: os contributors (grupo do cluster + grupos
   pré-existentes listados) recebem `role:app-contributor` +
   `role:readonly`, **exatamente como o role existe hoje**. Sem mudança em
   `rbac-config.yaml`.

   Ressalva registrada no brainstorming: `role:app-contributor` **inclui
   `applications, delete, default/*, allow`** (`rbac-config.yaml:4`). O
   nível aprovado foi descrito como "sync/restart, sem delete", mas a
   decisão final foi **aceitar o `delete`** para não alterar um template do
   módulo compartilhado `src/helm/modules/argo-cd` (usado também por
   `cluster_argocd_ingress_azure` e `cluster_argocd_ingress_nginx`). Ou
   seja: membros do grupo do cluster **podem deletar Applications** em
   `default/*`. Se isso for indesejado no futuro, a mudança é criar um role
   novo (ex.: `role:cluster-user`) em vez de editar `role:app-contributor`,
   para não afetar os exemplos legado.
5. **Lifecycle**: o grupo novo é destruído junto com o cluster (`terraform
   destroy`). Grupos pré-existentes listados em
   `argocd_extra_contributor_group_ids` **não são tocados** em momento
   algum — o Terraform nunca os cria, altera ou destrói; apenas referencia
   seus `object_id` no `policy.csv`.
6. **Fora de escopo**: RBAC por ArgoCD `AppProject` (opção descartada em
   favor do nível "contributor" simples, já suportado); grupo `aks-admin`
   por cluster (descartado, ver decisão 1).

## Riscos conhecidos

### Overage da claim `groups` (>200 grupos)

O RBAC do ArgoCD casa contra a claim `groups` do ID token
(`group_membership_claims = ["All"]`, já configurado em
`src/active-directory/app-registration/main.tf:14`). O Entra ID limita essa
claim a **200 grupos por JWT**. Acima disso o token não traz `groups`, e sim
os indicadores `_claim_names` / `hasgroups`.

O `oidc.config` do ArgoCD (`src/helm/modules/argo-cd/templates/sso.yaml`)
pede `requestedIDTokenClaims.groups.essential: true` e **não** usa
`getUserInfo` / Microsoft Graph como fallback. Consequência: um usuário
membro de muitos grupos loga com sucesso mas **sem nenhum grupo**, caindo em
`policy.default: role:empty` — perda de acesso **silenciosa**, sem erro
visível de autenticação.

A decisão 3 (listar grupos pré-existentes no `policy.csv` em vez de aninhá-los
no grupo do cluster) foi tomada em parte para **não consumir** esse orçamento:
o usuário casa pelo grupo que já carrega, sem precisar que o grupo do cluster
também esteja no token. O custo por cluster adicional é zero. Aninhar teria
custado +1 slot por cluster acessado.

Mitigação residual: fora de escopo (o ambiente atual está muito longe de 200
grupos), mas o comportamento deve ser documentado como gotcha no `CLAUDE.md`
para que um futuro "usuário não vê nada no ArgoCD" não seja diagnosticado
como bug de RBAC. Se o limite virar problema real, a saída é habilitar
`getUserInfo` no ArgoCD ou filtrar a claim por grupos atribuídos à aplicação.

### Edição de arquivo compartilhado

`examples/cluster_argocd_ingress_istio/variables.tf` é **symlink** para
`examples/common/variables.tf`, e `local.argocd_contributors_ids` também é
consumido por `cluster_argocd_ingress_azure/main.tf:116` e
`cluster_argocd_ingress_nginx/main.tf:105`.

Portanto: o override deve ser feito **apenas** no ponto de instanciação em
`examples/cluster_argocd_ingress_istio/main.tf:200`. O local
`argocd_contributors_ids` **não pode** ser removido de
`examples/common/variables.tf` — isso quebraria os outros dois exemplos.
Pelo mesmo motivo, o `module "cluster_access_group"` deve ser declarado no
`main.tf` do exemplo istio, nunca no `variables.tf` symlinkado.

## Permissão adicional necessária no Service Principal

Criar `azuread_group` via Terraform exige que o SP tenha permissão de
escrita em grupos no Azure AD — hoje o SP só tem `User Access Administrator`
na subscription (role Azure RBAC, escopo de recursos Azure) e permissões de
Microsoft Graph para `azuread_application` (app registration). Grupos são um
recurso de diretório separado; será necessário conceder ao SP a role de
diretório **Groups Administrator** (ou a permissão de aplicativo do
Microsoft Graph `Group.ReadWrite.All` com admin consent) — análogo ao papel
de `scripts/sp-grant-user-access-administrator`, mas para o diretório Azure
AD em vez da subscription Azure. O mecanismo exato (role de diretório via
`az rest`/Microsoft Graph API vs. permissão de aplicativo) fica para a fase
de implementação.

Nota: como a decisão 3 dispensou o `azuread_group_member`, **não** é
necessária a permissão `GroupMember.ReadWrite.All` — o Terraform só cria o
grupo do cluster, nunca gerencia membership de grupos existentes.

## Documentação a atualizar

- **`README.md` (raiz)**: tabela de scripts (linha ~64, ao lado de
  `sp-grant-aks-cluster-admin`) ganha uma entrada para o novo script/role
  necessário para criar grupos; texto próximo à linha 113 (que hoje só fala
  do grupo `aks-administrator`) ganha uma nota sobre o grupo de contributors
  ser criado por cluster.
- **`examples/cluster_argocd_ingress_istio/README.md`**: tabela de
  variáveis (linha ~158) — `argocd_contributors_ids` deixa de vir de
  `../common/variables.tf` (só `argocd_administrators_ids` continua vindo
  de lá); documentar o novo módulo `cluster-access-group` e o local
  `argocd_extra_contributor_group_ids`, deixando explícito que grupos
  pré-existentes recebem acesso por **referência no `policy.csv`**, não por
  membership no grupo do cluster.

## Testes / validação

- `terraform init -backend=false && terraform validate` no exemplo istio
  (sem credenciais).
- Validação real no próximo provisionamento do exemplo (já em andamento de
  migração, conforme estratégia acordada no `CLAUDE.md`):
  - Conta membro do grupo `aks-cluster-users-*` consegue logar no ArgoCD e
    ver/sincronizar/reiniciar Applications em `default/*` (incluindo
    `delete`, conforme decisão 4 — não é regressão).
  - Conta membro do grupo `aks-cluster-users-*` **não** consegue alterar
    configuração do ArgoCD (settings/repos/clusters), que é exclusivo de
    `role:admin`.
  - Conta membro de um grupo pré-existente informado em
    `argocd_extra_contributor_group_ids` tem o mesmo comportamento acima
    (casa direto pelo `object_id` do próprio grupo no `policy.csv`, sem
    depender de expansão transitiva).
  - Conferir no `policy.csv` renderizado (`kubectl -n argocd get cm
    argocd-rbac-cm -o yaml`) que há um par `role:app-contributor` /
    `role:readonly` por id — o do grupo do cluster mais um por grupo extra.
  - Conta fora de qualquer grupo cai em `role:empty` (nega tudo).
  - Conta do grupo `aks-admin` continua com acesso total, sem mudança.
