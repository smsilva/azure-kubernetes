# Shared modules vs. provider versions

`src/cluster`, `src/nodepool`, and `src/helm/modules/*` are shared by all 5
examples, but each example pins a different provider version. **Editing a
shared module affects every example.**

| Example | azurerm | helm | State |
|---|---|---|---|
| `cluster_argocd_ingress_istio` | **>= 5.0** | **>= 3.0** | migration in progress |
| `cluster_argocd_ingress_azure` | >= 4.0 | >= 3.0 | earlier partial migration |
| `cluster_argocd_ingress_nginx` | >= 3.0 | (unpinned) | legacy |
| `cluster_one_nodepool` | >= 3.0 | — | legacy |
| `cluster_two_nodepools` | >= 3.0 | — | legacy (uses `src/nodepool`) |

## Agreed strategy

Migrate **one example at a time**, starting with
`cluster_argocd_ingress_istio`. The rest stay on old versions (and may be
temporarily broken with respect to the shared modules) until the example in
focus has been really provisioned, validated, and destroyed.

## Known incompatibilities

- `node_provisioning_profile` (`src/cluster/main.tf`) only exists in azurerm v5 →
  breaks the v3/v4 examples.
- Renames in `src/nodepool` (`auto_scaling_enabled`, `node_public_ip_enabled`,
  `host_encryption_enabled`) are v4+ → break v3 examples.
- helm `set = [...]` (list) syntax is v3; `set {...}` (block) is v2. Do not mix
  them in the same module.
- helm v3: `provider "helm"` takes `kubernetes = {...}` (attribute), not a block.
- `azurerm_federated_identity_credential` in v5 uses `user_assigned_identity_id`;
  it accepts neither `parent_id` nor `resource_group_name`.
- Pod labels set through helm `set` need `type = "string"` (e.g.
  `azure.workload.identity/use = "true"`), otherwise helm infers a boolean and
  Kubernetes rejects the label.

## Expected breakage (not a regression)

- `cluster_argocd_ingress_azure` and `cluster_argocd_ingress_nginx` fail
  `terraform validate`: `identity_client_id` became required in the
  `external-dns` module, but these examples still pass the pre-Workload-Identity
  `client_id`/`client_secret`.
- The `ingress-azure` chart was removed — affects only the azure example.
