# Terraform / Azure

## SP permissions

- Needs `User Access Administrator` (not just `Contributor`) to create the
  examples' `azurerm_role_assignment` resources →
  `scripts/sp-grant-user-access-administrator --client-id <id>`.
- The `waspfoundation*` Key Vault uses access policies (RBAC disabled) → grant
  identities access with `azurerm_key_vault_access_policy`, not a role
  assignment.

## `kubernetes`/`helm` providers in the istio example

They use `kube_config` + `exec`/`kubelogin --login azurecli` (not
`kube_admin_config`). Membership in the cluster's `admin_group_object_ids` group
(with `azure_rbac_enabled = true`) already grants cluster-admin-equivalent
access through Azure RBAC — no dedicated role assignment needed.

`--login azurecli` rather than `spn`: `spn` requires `ARM_CLIENT_SECRET`, which
is absent in CI using federated OIDC (`ARM_USE_OIDC=true`); `azurecli` reuses
the already-authenticated session (locally: `az login`; CI: `azure/login@v2`)
with no environment `if`. The exec plugin's `server-id` is the fixed AKS AAD
Server app ID: `6dae42f8-4368-4678-94ff-3960e28e3630`.

Note: `kube_admin_config`/password still show up in `terraform state` — it is an
attribute of `azurerm_kubernetes_cluster`, exposed whenever
`disable_local_accounts != true`. The switch removes the providers' *use* of it,
not its presence in state.

kubectl access without `kubelogin`:
`az aks get-credentials --resource-group <rg> --name <cluster> --admin --overwrite-existing`.

## Tagging the RG and the cluster in the same apply forces a replace

`src/cluster` reads `data.azurerm_resource_group.default.location`. While the RG
has a pending change that data source stays "known after apply", making
`location` (a `ForceNew` field of the AKS) unknown — which triggers a `-/+` on
the cluster and cascades to the `kubernetes`/`helm` providers, recreating every
helm release.

Mitigation: apply in two stages with `-target` (RG first, on its own; only then
the cluster module) — the AKS then completes as an `update in-place`. One
`azurerm_role_assignment` is still recreated (same effect, smaller scale).

## Benign warning on destroy

cert-manager (and Istio) CRDs are kept by `resource-policy: keep` on
`helm uninstall`. Since the whole cluster is destroyed along with them, they go
away with the control plane — nothing is orphaned in Azure.

## `scripts/update-local-helm-charts`

It is NOT just a check: it does `rm -rf` + `helm fetch --untar` and **replaces**
the local charts whenever the remote version differs. Run it only when you
actually want to update.

The helm provider does not detect a change when only the **content of a local
chart** changes (same `values`/`set`). Force it with
`terraform apply -replace='module.<mod>[0].helm_release.<release>'` — except for
`istio_gateway`, see `docs/reference/istio-tls-ingress.md`.

## CI: SSH access to private modules (`git::ssh`)

- `network.tf`/`secrets.tf` pull `vnet` and `argocd_app_registration_password`
  from `git::ssh://git@github.com/smsilva/{azure-network,azure-key-vault}.git` —
  private repos, with no access by default on a GitHub Actions runner.
- GitHub rejects the same public key as a deploy key on more than one repository
  (`422 key is already in use`). Solution: one key per module repo
  (`scripts/github-actions-configure-ssh-deploy-key`), mapped through a host
  alias in `~/.ssh/config` +
  `git config url."ssh://git@github.com-<repo>/...".insteadOf "ssh://git@github.com/..."`.
- The `insteadOf` must match the **exact** URL: Terraform's git module detector
  produces `ssh://git@github.com/owner/repo` (full URL), not the SCP-like form
  `git@github.com:owner/repo`. Using the wrong form makes the `insteadOf` never
  match, silently (the clone falls back to the default identity).
- `local.arm_client_secret`/`module "variables"` (`src/variables`) are only used
  by `cluster_argocd_ingress_azure` and `cluster_argocd_ingress_nginx` — they
  live in files owned by those examples, not in `examples/common/variables.tf`
  (istio does not pay the cost of the `data "external"` on every plan).

→ Setup and bootstrap: [`../ci-oidc-federation.md`](../ci-oidc-federation.md).
