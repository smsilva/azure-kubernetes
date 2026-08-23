# ArgoCD (`cluster_argocd_ingress_istio` example)

## azuread SSO

The clientSecret is written to the Key Vault by
`argocd_app_registration_password` and injected into `argocd-secret` through the
`argocd-secret-merge-oidc-azuread` ExternalSecret (`creationPolicy: Merge`).
Validate with `GET /api/v1/settings` → `oidcConfig.name=AzureAD`.

## Access / RBAC

Contributor access comes from an `azuread_group` created per cluster
(`aks-cluster-users-<random_id>`, module
`src/active-directory/cluster-access-group`), destroyed along with the cluster.
Pre-existing AD groups get the same access by being **listed** in
`local.argocd_extra_contributor_group_ids`
(`examples/cluster_argocd_ingress_istio/variables-cluster-access.tf`) → they
become entries in `policy.csv`.

Do **not** nest groups inside the cluster group: it would spend a slot of the
JWT's 200-group quota and depend on transitive expansion of the claim.

Requires `Groups Administrator` on the Terraform SP
(`scripts/sp-grant-groups-administrator`). Note: the script's idempotency check
queries `servicePrincipals/{id}/memberOf` (principal side), not
`directoryRoles/{id}/members` — the latter has real propagation delay in
Microsoft Graph (confirmed live: the grant worked, but `members` still did not
list the SP a minute later, causing a rejected duplicate `POST`).

### User logs in but "sees nothing"

Falls through to `policy.default: role:empty`. Before investigating RBAC, check
whether the token carried the `groups` claim. Entra truncates the claim above
**200 groups** and sends `_claim_names`/`hasgroups` instead; the `oidc.config`
in `src/helm/modules/argo-cd/templates/sso.yaml` does not use `getUserInfo` as a
fallback, so the loss of access is silent. Way out: enable `getUserInfo` or
filter the claim to groups assigned to the application.

## App-of-apps

Points at the external repo `git@github.com:smsilva/wasp-gitops.git` (branch
`dev`, path `infrastructure/charts/applications`) over SSH. The key is
`secret/argocd-repo-creds-ssh-private-key-base64-encoded` in the Key Vault
(base64 WITHOUT line breaks: `base64 -w0`), injected by the
`argocd-repo-creds-github` ExternalSecret. When rotating the local SSH key,
update that secret in AKV or the sync fails on GitHub auth.
