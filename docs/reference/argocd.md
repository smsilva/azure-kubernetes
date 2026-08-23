# ArgoCD (exemplo `cluster_argocd_ingress_istio`)

## SSO azuread

O clientSecret é gravado no Key Vault por `argocd_app_registration_password` e
injetado em `argocd-secret` via ExternalSecret `argocd-secret-merge-oidc-azuread`
(`creationPolicy: Merge`). Validar com `GET /api/v1/settings` →
`oidcConfig.name=AzureAD`.

## Acesso / RBAC

Contributor vem de um `azuread_group` criado por cluster
(`aks-cluster-users-<random_id>`, módulo `src/active-directory/cluster-access-group`),
destruído junto com o cluster. Grupos AD pré-existentes ganham o mesmo acesso sendo
**listados** em `local.argocd_extra_contributor_group_ids`
(`examples/cluster_argocd_ingress_istio/variables-cluster-access.tf`) → viram entradas
no `policy.csv`.

**Não** aninhar grupos no grupo do cluster: gastaria um slot da cota de 200 grupos do
JWT e dependeria de expansão transitiva da claim.

Requer `Groups Administrator` no SP do Terraform (`scripts/sp-grant-groups-administrator`).
Atenção: a checagem de idempotência do script consulta `servicePrincipals/{id}/memberOf`
(lado do principal), não `directoryRoles/{id}/members` — este último tem atraso real de
propagação no Microsoft Graph (confirmado ao vivo: grant funcionou, mas `members` ainda
não listava o SP um minuto depois, causando um `POST` duplicado rejeitado).

### Usuário loga mas "não vê nada"

Cai em `policy.default: role:empty`. Antes de investigar RBAC, checar se o token trouxe
a claim `groups`. O Entra corta a claim acima de **200 grupos** e manda
`_claim_names`/`hasgroups` no lugar; o `oidc.config` em
`src/helm/modules/argo-cd/templates/sso.yaml` não usa `getUserInfo` como fallback, então
a perda de acesso é silenciosa. Saída: habilitar `getUserInfo` ou filtrar a claim por
grupos atribuídos à aplicação.

## App-of-apps

Aponta para o repo externo `git@github.com:smsilva/wasp-gitops.git` (branch `dev`, path
`infrastructure/charts/applications`) via SSH. A chave é
`secret/argocd-repo-creds-ssh-private-key-base64-encoded` no Key Vault (base64 SEM
quebras: `base64 -w0`), injetada por ExternalSecret `argocd-repo-creds-github`. Ao trocar
a chave SSH local, atualizar esse secret no AKV senão o sync falha na auth do GitHub.
