# Cluster-Scoped ArgoCD Access Group Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give `cluster_argocd_ingress_istio` an Azure AD group created per cluster that grants ArgoCD contributor access, plus an opt-in list of pre-existing AD groups granted the same access by reference in `policy.csv`.

**Architecture:** A new leaf module `src/active-directory/cluster-access-group` creates one `azuread_group` and exports its `object_id`. The istio example concatenates that id with an example-local list of pre-existing group ids and passes the result to the existing `contributors_ids` input of `src/helm/modules/argo-cd`. The `argo-cd` module and its `rbac-config.yaml` template are **not modified** — the template already loops over the list.

**Tech Stack:** Terraform, `hashicorp/azuread` provider (>= 3.0.0, < 4.0.0), Bash + `az` CLI + Microsoft Graph REST.

**Spec:** [`docs/superpowers/specs/2026-08-23-argocd-cluster-scoped-access-design.md`](../specs/2026-08-23-argocd-cluster-scoped-access-design.md)

## Global Constraints

- **Scope is `examples/cluster_argocd_ingress_istio` only.** The other four examples must keep working. Per `CLAUDE.md`, `src/helm/modules/*` are shared by all examples — do **not** edit `src/helm/modules/argo-cd` in this plan.
- **`examples/common/variables.tf` is a symlink** reached as `examples/cluster_argocd_ingress_istio/variables.tf`. `local.argocd_contributors_ids` there is consumed by `examples/cluster_argocd_ingress_azure/main.tf:116` and `examples/cluster_argocd_ingress_nginx/main.tf:105`. **Never remove or edit it.**
- **Run `terraform fmt` before committing** (per `CLAUDE.md` conventions). Do **not** run `terraform fmt -recursive examples` — it follows the symlinks into `examples/common/` and reformats shared files.
- **Validation command** (no credentials needed): `terraform init -backend=false && terraform validate`.
- **No Terraform test framework exists in this repo** (no `*.tftest.hcl`). The per-task gate is `terraform validate` plus reading the generated config. Behavioural validation happens in Task 5 against a real cluster and is run by the user.
- **Bash conventions** (per `CLAUDE.md`): no file extension on executables, long-form CLI options, 2-space indent, `do`/`then` on the same line, lowercase locals / UPPERCASE env vars, always quote `"${variable}"`, `set -e` for sequential scripts.
- `.terraform.lock.hcl` is **not** versioned — never `git add` it.

---

### Task 1: The `cluster-access-group` module

Creates the per-cluster Azure AD group. Nothing else — no membership management (see spec decision 3).

**Files:**
- Create: `src/active-directory/cluster-access-group/main.tf`
- Create: `src/active-directory/cluster-access-group/variables.tf`
- Create: `src/active-directory/cluster-access-group/outputs.tf`

**Interfaces:**
- Consumes: nothing from earlier tasks.
- Produces: module at source path `../../src/active-directory/cluster-access-group` with inputs `name` (string, required) and `description` (string, optional, default `""`); outputs `object_id` (string) and `display_name` (string). Task 2 consumes `object_id`.

- [ ] **Step 1: Write `variables.tf`**

Mirrors the style of the sibling `src/active-directory/app-registration/variables.tf` (typed, with `description`).

```hcl
variable "name" {
  type        = string
  description = "Azure AD security group display name"
}

variable "description" {
  type        = string
  description = "Azure AD security group description, shown in the Entra portal"
  default     = ""
}
```

- [ ] **Step 2: Write `main.tf`**

`owners` follows the exact pattern of `src/active-directory/app-registration/main.tf:12` — the Terraform Service Principal owns what it creates. `prevent_duplicate_names` turns a name collision into a plan-time error instead of a second group silently appearing in the directory.

```hcl
data "azuread_client_config" "current" {}

resource "azuread_group" "default" {
  display_name            = var.name
  description             = var.description
  owners                  = [data.azuread_client_config.current.object_id]
  security_enabled        = true
  mail_enabled            = false
  prevent_duplicate_names = true
}
```

- [ ] **Step 3: Write `outputs.tf`**

```hcl
output "object_id" {
  value = azuread_group.default.object_id
}

output "display_name" {
  value = azuread_group.default.display_name
}
```

- [ ] **Step 4: Format and validate the module in isolation**

Run:
```bash
cd src/active-directory/cluster-access-group
terraform fmt
terraform init -backend=false && terraform validate
```
Expected: `Success! The configuration is valid.`

Then remove the init artifacts so they are not committed:
```bash
rm -rf .terraform .terraform.lock.hcl
```

- [ ] **Step 5: Commit**

```bash
cd "$(git rev-parse --show-toplevel)"
git add src/active-directory/cluster-access-group
git commit -m "feat(active-directory): add cluster-access-group module

Creates one Azure AD security group per cluster, owned by the Terraform
Service Principal. Membership of pre-existing groups is deliberately not
managed here — they are granted access by reference in the ArgoCD
policy.csv instead (see spec decision 3)."
```

---

### Task 2: Wire the module into the istio example

**Files:**
- Create: `examples/cluster_argocd_ingress_istio/variables-cluster-access.tf`
- Modify: `examples/cluster_argocd_ingress_istio/main.tf` (add module block after the `argocd_app_registration` block ending at line 54; change `contributors_ids` at line 200)
- Modify: `examples/cluster_argocd_ingress_istio/outputs.tf` (append)

**Interfaces:**
- Consumes: `module.cluster_access_group[0].object_id` and `.display_name` from Task 1.
- Produces: output `argocd_access_group_name` (string) — the group an operator adds users to. Task 4 documents it.

- [ ] **Step 1: Create `variables-cluster-access.tf`**

A new file, not an edit to `variables.tf` — that path is a **symlink to the shared `examples/common/variables.tf`**. This follows the existing precedent `examples/cluster_argocd_ingress_azure/variables-arm-client-secret.tf`, which exists for exactly this reason.

```hcl
# Access to this cluster's ArgoCD is granted to two kinds of Azure AD group:
#
#   1. local.argocd_cluster_access_group_name — created by this example, one
#      per cluster, destroyed with it. Add individual users here.
#   2. local.argocd_extra_contributor_group_ids — pre-existing groups in the
#      directory. They are granted access by *reference* in the ArgoCD
#      policy.csv, never by being nested into the group above: nesting would
#      spend one slot of the 200-group JWT claim budget per cluster, and would
#      depend on transitive claim expansion. See the design spec.
#
# Both land in role:app-contributor + role:readonly. Changing the list below
# requires a terraform apply, which is intended — access is granted through a
# reviewed pull request.

locals {
  argocd_cluster_access_group_name = "aks-cluster-users-${local.cluster_random_id}"

  argocd_extra_contributor_group_ids = []
}
```

- [ ] **Step 2: Add the module block to `main.tf`**

Insert immediately after the closing `}` of the `argocd_app_registration` module (currently line 54), so the two ArgoCD identity concerns sit together. `count` is tied to `local.install_argocd` exactly like its neighbour — no ArgoCD, no group.

```hcl
module "cluster_access_group" {
  count  = local.install_argocd ? 1 : 0
  source = "../../src/active-directory/cluster-access-group"

  name        = local.argocd_cluster_access_group_name
  description = "ArgoCD contributor access to AKS cluster ${local.cluster_name}. Created and destroyed with the cluster."
}
```

- [ ] **Step 3: Point `contributors_ids` at the concatenated list in `main.tf`**

Replace line 200 exactly:

```hcl
  contributors_ids            = local.argocd_contributors_ids
```

with:

```hcl
  contributors_ids = concat(
    [module.cluster_access_group[0].object_id],
    local.argocd_extra_contributor_group_ids,
  )
```

Then add `module.cluster_access_group` to the `depends_on` list of the same `module "argo_cd"` block (currently lines 207-213), so the group exists before the RBAC referencing it is applied:

```hcl
  depends_on = [
    module.argocd_app_registration,
    module.cert_manager,
    module.cluster_access_group,
    module.external_dns,
    module.external_secrets,
    module.ingress_istio,
  ]
```

Note: `local.argocd_contributors_ids` is now unused **by this example**. Leave it in `examples/common/variables.tf` — the azure and nginx examples still read it.

- [ ] **Step 4: Append the operator-facing output to `outputs.tf`**

```hcl
output "argocd_access_group_name" {
  value = local.install_argocd ? module.cluster_access_group[0].display_name : null
}
```

- [ ] **Step 5: Format and validate**

Run:
```bash
cd examples/cluster_argocd_ingress_istio
terraform fmt
terraform init -backend=false && terraform validate
```
Expected: `Success! The configuration is valid.`

- [ ] **Step 6: Confirm the shared file was not touched**

Run:
```bash
cd "$(git rev-parse --show-toplevel)"
git status --short examples/common/
```
Expected: **empty output**. Any change under `examples/common/` means a symlink was edited by mistake — revert it before continuing.

- [ ] **Step 7: Confirm the other examples still validate**

The shared modules were not edited, so this should be unchanged from before the task. Run:
```bash
cd examples/cluster_argocd_ingress_azure
terraform init -backend=false && terraform validate
```
Expected: this example **fails** with `identity_client_id is required` — a **pre-existing** failure documented in `CLAUDE.md` ("Consequência da mudança acima"), not a regression from this plan. Confirm the error text mentions `identity_client_id` and nothing about `contributors_ids` or `cluster-access-group`.

- [ ] **Step 8: Commit**

```bash
cd "$(git rev-parse --show-toplevel)"
git add examples/cluster_argocd_ingress_istio/variables-cluster-access.tf \
        examples/cluster_argocd_ingress_istio/main.tf \
        examples/cluster_argocd_ingress_istio/outputs.tf
git commit -m "feat(istio): grant ArgoCD access via per-cluster AD group

The cluster group replaces the shared aks-contributor id as this
example's ArgoCD contributor. Pre-existing groups can be added to
local.argocd_extra_contributor_group_ids, which is concatenated into
contributors_ids and rendered as one policy.csv entry each.

local.argocd_contributors_ids stays in the shared common/variables.tf —
the azure and nginx examples still consume it."
```

---

### Task 3: `sp-grant-groups-administrator` script

The Terraform Service Principal cannot create `azuread_group` today. Group creation is a **directory** permission, unrelated to the subscription-scoped `User Access Administrator` that `sp-grant-user-access-administrator` grants.

**Files:**
- Create: `scripts/sp-grant-groups-administrator`

**Interfaces:**
- Consumes: nothing from earlier tasks.
- Produces: an executable taking `--client-id <appId>`; no Terraform code depends on it.

- [ ] **Step 1: Write the script**

Structure, flag parsing, and output style mirror `scripts/sp-grant-user-access-administrator` so the two read alike. The Graph flow is three calls because a directory role must be *activated* from its template before anything can be assigned to it — a freshly-created tenant may have no activated `Groups Administrator` role at all. Looking the template up by `displayName` avoids hardcoding a role GUID.

```bash
#!/bin/bash
set -e

export THIS_SCRIPT_NAME=$0
export THIS_SCRIPT_DIRECTORY=$(dirname $0)
export PATH=${PATH}:${THIS_SCRIPT_DIRECTORY}

show_usage() {
  cat <<EOF

  Grants the "Groups Administrator" Entra ID directory role to a Service
  Principal, so Terraform can create the azuread_group resource backing
  per-cluster ArgoCD access.

  This is a directory role, not an Azure RBAC role: it is unrelated to the
  subscription-scoped grant made by sp-grant-user-access-administrator, and
  both are needed.

  The caller must be Privileged Role Administrator or Global Administrator.

  ${THIS_SCRIPT_NAME} \\
    --client-id 2ef8b61a-e93b-453b-bb02-96e2394a518a

EOF
}

while [[ "$1" =~ ^- && ! "$1" == "--" ]]; do
case $1 in
  -h | --help )
    show_usage
    exit
    ;;

  -c | --client-id )
    shift; ARM_CLIENT_ID=$1
    ;;
esac; shift; done

if [[ "$1" == '--' ]]; then shift; fi

if [ -z "${ARM_CLIENT_ID}" ]; then
  show_usage
  exit 1
fi

role_name="Groups Administrator"
graph_url="https://graph.microsoft.com/v1.0"

principal_id=$(az ad sp show \
  --id "${ARM_CLIENT_ID}" \
  --query id \
  --output tsv)

echo "Service Principal.: ${ARM_CLIENT_ID}"
echo "Object Id.........: ${principal_id}"
echo "Role..............: ${role_name}"

template_id=$(az rest \
  --method GET \
  --url "${graph_url}/directoryRoleTemplates" \
  --query "value[?displayName=='${role_name}'].id | [0]" \
  --output tsv)

if [ -z "${template_id}" ]; then
  echo "Role template not found: ${role_name}"
  exit 1
fi

role_id=$(az rest \
  --method GET \
  --url "${graph_url}/directoryRoles" \
  --query "value[?roleTemplateId=='${template_id}'].id | [0]" \
  --output tsv)

if [ -z "${role_id}" ]; then
  echo "Role not activated in this tenant yet. Activating."

  role_id=$(az rest \
    --method POST \
    --url "${graph_url}/directoryRoles" \
    --headers "Content-Type=application/json" \
    --body "{\"roleTemplateId\": \"${template_id}\"}" \
    --query id \
    --output tsv)
fi

echo "Role Id...........: ${role_id}"

existing=$(az rest \
  --method GET \
  --url "${graph_url}/directoryRoles/${role_id}/members" \
  --query "length(value[?id=='${principal_id}'])" \
  --output tsv)

if [ "${existing}" != "0" ]; then
  echo "Already assigned. Nothing to do."
  exit 0
fi

az rest \
  --method POST \
  --url "${graph_url}/directoryRoles/${role_id}/members/\$ref" \
  --headers "Content-Type=application/json" \
  --body "{\"@odata.id\": \"${graph_url}/directoryObjects/${principal_id}\"}"

echo "Granted."
```

- [ ] **Step 2: Make it executable and check it parses**

Run:
```bash
chmod +x scripts/sp-grant-groups-administrator
bash -n scripts/sp-grant-groups-administrator
```
Expected: no output from `bash -n` (syntax OK).

- [ ] **Step 3: Verify the usage path works without touching Azure**

Run:
```bash
scripts/sp-grant-groups-administrator --help
scripts/sp-grant-groups-administrator; echo "exit=$?"
```
Expected: the usage text both times; the second invocation prints `exit=1` because `--client-id` is missing.

- [ ] **Step 4: Confirm it matches the sibling script's conventions**

Run:
```bash
diff <(head -7 scripts/sp-grant-user-access-administrator) \
     <(head -7 scripts/sp-grant-groups-administrator)
```
Expected: no differences — same shebang, `set -e`, and `THIS_SCRIPT_*` / `PATH` preamble.

- [ ] **Step 5: Commit**

```bash
git add scripts/sp-grant-groups-administrator
git commit -m "feat(scripts): add sp-grant-groups-administrator

Grants the Entra directory role that lets the Terraform Service
Principal create azuread_group. Activates the role from its template
first, since a tenant that has never used it has no activated role to
assign to."
```

---

### Task 4: Documentation

**Files:**
- Modify: `README.md` (script table ending at line 64; "Why the Entra group instead of a role assignment" section around line 113)
- Modify: `examples/cluster_argocd_ingress_istio/README.md` (component table line 27; knobs table line 158; Outputs section)
- Modify: `CLAUDE.md` (append two gotchas)

**Interfaces:**
- Consumes: the output name `argocd_access_group_name` from Task 2 and the script name from Task 3.
- Produces: nothing consumed by later tasks.

- [ ] **Step 1: Add the script to the root `README.md` table**

Append this row directly below the `sp-grant-aks-cluster-admin` row (line 64):

```markdown
| [`sp-grant-groups-administrator`](scripts/sp-grant-groups-administrator) | Entra ID | grants the Service Principal the `Groups Administrator` directory role, required to create the per-cluster ArgoCD access group |
```

- [ ] **Step 2: Extend the "Why the Entra group instead of a role assignment" section of the root `README.md`**

Append after the paragraph ending "start a new CI job." (around line 118):

```markdown
That covers **administrators**, who are the same group in every cluster.
Contributors are not: `cluster_argocd_ingress_istio` creates a group per
cluster (`aks-cluster-users-<id>`, via
[`src/active-directory/cluster-access-group`](src/active-directory/cluster-access-group))
that is destroyed with the cluster. Pre-existing groups can be granted the
same access by listing their object IDs in the example's
`local.argocd_extra_contributor_group_ids` — they are referenced from the
ArgoCD `policy.csv`, never nested into the per-cluster group.
```

- [ ] **Step 3: Update the component table in the istio `README.md`**

Replace line 27 exactly:

```markdown
| ArgoCD | `install_argocd` | `true` | `src/helm/modules/argo-cd` + `src/active-directory/app-registration` | ArgoCD chart 10.4.0 (app v3.5.1) with Azure AD SSO |
```

with:

```markdown
| ArgoCD | `install_argocd` | `true` | `src/helm/modules/argo-cd` + `src/active-directory/app-registration` + `src/active-directory/cluster-access-group` | ArgoCD chart 10.4.0 (app v3.5.1) with Azure AD SSO, contributor access via a per-cluster AD group |
```

- [ ] **Step 4: Update the knobs table in the istio `README.md`**

Replace line 158 exactly:

```markdown
| `argocd_administrators_ids` / `argocd_contributors_ids` | [`../common/variables.tf`](../common/variables.tf) | Azure AD group object IDs mapped to ArgoCD RBAC |
```

with these two rows:

```markdown
| `argocd_administrators_ids` | [`../common/variables.tf`](../common/variables.tf) | Azure AD group object ID mapped to ArgoCD `role:admin`; shared by every example |
| `argocd_extra_contributor_group_ids` | [`variables-cluster-access.tf`](variables-cluster-access.tf) | pre-existing Azure AD group object IDs granted `role:app-contributor` on **this** cluster, referenced from `policy.csv` |
```

Note this example no longer reads `local.argocd_contributors_ids`, which is why it leaves the table — but it is still defined in the shared file for the azure and nginx examples.

- [ ] **Step 5: Document the new output in the istio `README.md`**

In the `## Outputs` section, add a row/entry for:

```markdown
| `argocd_access_group_name` | display name of the Azure AD group to add users to for ArgoCD contributor access on this cluster |
```

Match the existing formatting of that section — read it first and follow whatever table or list shape is already there.

- [ ] **Step 6: Append two gotchas to `CLAUDE.md`**

Add to the "Gotchas operacionais" bullet list:

```markdown
- Acesso de contributor ao ArgoCD do exemplo istio vem de um `azuread_group` criado por cluster (`aks-cluster-users-<random_id>`, módulo `src/active-directory/cluster-access-group`), destruído junto com o cluster. Grupos AD pré-existentes ganham o mesmo acesso sendo **listados** em `local.argocd_extra_contributor_group_ids` (`examples/cluster_argocd_ingress_istio/variables-cluster-access.tf`) → viram entradas no `policy.csv`. **Não** aninhar grupos no grupo do cluster: o nesting gastaria um slot da cota de 200 grupos do JWT por cluster e dependeria de expansão transitiva da claim. Requer `Groups Administrator` no SP do Terraform (`scripts/sp-grant-groups-administrator`).
- Usuário loga no ArgoCD mas "não vê nada" (cai em `policy.default: role:empty`): antes de investigar RBAC, checar se o token trouxe a claim `groups`. O Entra corta a claim acima de **200 grupos** e manda `_claim_names`/`hasgroups` no lugar; o `oidc.config` em `src/helm/modules/argo-cd/templates/sso.yaml` não usa `getUserInfo` como fallback, então a perda de acesso é silenciosa. Saída, se acontecer: habilitar `getUserInfo` ou filtrar a claim por grupos atribuídos à aplicação.
```

- [ ] **Step 7: Verify no shared file was touched and links resolve**

Run:
```bash
git status --short examples/common/
ls src/active-directory/cluster-access-group \
   scripts/sp-grant-groups-administrator \
   examples/cluster_argocd_ingress_istio/variables-cluster-access.tf
```
Expected: empty output from `git status`; all three paths listed by `ls` (every path referenced by the new markdown links exists).

- [ ] **Step 8: Commit**

```bash
git add README.md examples/cluster_argocd_ingress_istio/README.md CLAUDE.md
git commit -m "docs: document per-cluster ArgoCD access group

Covers the new module and script, the extra-contributor list, and two
gotchas: why pre-existing groups are referenced rather than nested, and
the silent role:empty failure when the groups claim overflows."
```

---

### Task 5: Live validation (requires Azure credentials — run by the user)

Everything above is verifiable without credentials. This task is the spec's "Testes / validação" section and needs a real cluster. Do **not** mark it complete from a plan or a `terraform plan` alone.

**Files:** none — this task changes no code.

**Interfaces:**
- Consumes: everything from Tasks 1-4.
- Produces: a go/no-go on the design.

- [ ] **Step 1: Grant the directory role, then confirm the plan is clean**

```bash
scripts/sp-grant-groups-administrator --client-id "${ARM_CLIENT_ID}"
cd examples/cluster_argocd_ingress_istio
terraform plan
```
Expected: `module.cluster_access_group[0].azuread_group.default` to be **created**, and the `argo_cd` helm release to show an **update** (not a replace) of its RBAC values.

- [ ] **Step 2: Apply and read back the rendered policy**

```bash
terraform apply
terraform output argocd_access_group_name
kubectl --namespace argocd get configmap argocd-rbac-cm --output yaml
```
Expected in `policy.csv`: one `g, "<id>", role:app-contributor` **and** one `g, "<id>", role:readonly` line per contributor id — the cluster group, plus one pair per entry of `argocd_extra_contributor_group_ids`; plus the unchanged `g, "<id>", role:admin` line for the administrators group.

- [ ] **Step 3: Verify the four access outcomes**

Add a test user to the group named by `terraform output argocd_access_group_name`, then check each case in the ArgoCD UI:

| Account | Expected |
| --- | --- |
| Member of the per-cluster group | logs in; can get / sync / restart / **delete** Applications in `default/*` (delete is intentional — spec decision 4) |
| Member of the per-cluster group | **cannot** reach ArgoCD settings, repositories, or clusters — those are `role:admin` only |
| Member of a group listed in `argocd_extra_contributor_group_ids` | identical to the first row, matched directly by its own object ID with no transitive expansion |
| Member of no listed group | logs in but sees nothing — `policy.default: role:empty` |
| Member of `aks-administrator` | full access, unchanged from before this work |

Group membership travels inside the token: after changing membership, run `az account clear` and sign in again, or the old token will still be presented.

- [ ] **Step 4: Confirm the group's lifecycle**

```bash
terraform destroy
az ad group list --filter "startswith(displayName, 'aks-cluster-users-')" --output table
```
Expected: the group for the destroyed cluster is gone. Any group listed in `argocd_extra_contributor_group_ids` must still exist — Terraform never manages those.

---

## Self-Review

**Spec coverage:**

| Spec item | Task |
| --- | --- |
| Decision 1 — `aks-admin` stays shared, untouched | Task 2 Step 3 leaves `administrators_ids` alone; Task 4 Step 4 documents it |
| Decision 2 — new module, group only, no `azuread_group_member` | Task 1 |
| Decision 3 — pre-existing groups via `concat` into `contributors_ids` | Task 2 Steps 1, 3 |
| Decision 4 — `role:app-contributor` unchanged, delete accepted | Task 2 Step 3 (no module edit); Task 5 Step 3 asserts delete works |
| Decision 5 — lifecycle; pre-existing groups untouched | Task 5 Step 4 |
| Decision 6 — AppProject / per-cluster admin group out of scope | not implemented, by design |
| Risk: groups claim overage | Task 4 Step 6, second gotcha |
| Risk: shared symlinked file | Global Constraints; Task 2 Steps 1, 6; Task 4 Step 7 |
| SP permission | Task 3 |
| Docs to update (both READMEs) | Task 4 |
| Testes / validação | Task 5 |

**Placeholder scan:** no TBD/TODO; every code step carries the literal file content or the exact before/after text. Task 4 Step 5 defers to the file's existing formatting rather than guessing a table shape — the section must be read first, which is stated in the step.

**Type consistency:** module inputs `name` / `description` (Task 1 Step 1) match the call site (Task 2 Step 2). Outputs `object_id` / `display_name` (Task 1 Step 3) match their consumers (Task 2 Steps 3, 4). `local.argocd_extra_contributor_group_ids` and `local.argocd_cluster_access_group_name` are defined in Task 2 Step 1 before use in Steps 2-3. `argocd_access_group_name` is named identically in Task 2 Step 4, Task 4 Step 5, and Task 5 Steps 2-3.
