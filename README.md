# Prerequisites

- Azure Subscrition
- Azure Service Principal
- Azure Key Vault
- Azure DNS Zone

## Service Principal Permissions

The Service Principal used by Terraform (`ARM_CLIENT_ID`) needs more than the
`Contributor` role: the examples create `azurerm_role_assignment` resources
(kubelet Contributor, AKS Cluster User Role, DNS Zone Contributor), which
require the `Microsoft.Authorization/roleAssignments/write` permission.

Grant the `User Access Administrator` role at the subscription scope. The
caller running the command must be `Owner` or `User Access Administrator`.

```bash
scripts/sp-grant-user-access-administrator \
  --client-id ${ARM_CLIENT_ID}
```

Without it, `terraform apply` fails with `403 AuthorizationFailed` on the
role assignment resources.

## GitHub Actions OIDC Federation (CI)

CI authenticates to Azure through **workload identity federation**: GitHub
Actions mints a short-lived OIDC token, Entra ID exchanges it for an access
token, and no client secret is ever stored in the repository. This matters
here because `smsilva/azure-kubernetes` is a public repository.

Availability is not a paid feature. OIDC token issuance (`id-token: write`)
works on every GitHub plan, including a free personal account, and federated
identity credentials are free in any Entra tenant (limit: 20 per app
registration). Public repositories also get Environments and unlimited Actions
minutes at no cost.

The workflow that proves the setup is
[`.github/workflows/azure-oidc-federation.yml`](.github/workflows/azure-oidc-federation.yml).
It only reads: it never runs `terraform apply`.

### 1. Create the deployment environment

The federated credential is bound to an environment rather than a branch, so
the workflow can be dispatched from any branch and can carry an approval gate.

```bash
gh api \
  --method PUT \
  repos/smsilva/azure-kubernetes/environments/azure-sandbox
```

### 2. Create the federated credential

```bash
az ad app federated-credential create \
  --id "${ARM_CLIENT_ID}" \
  --parameters '{
    "name": "github-actions-azure-sandbox",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:smsilva/azure-kubernetes:environment:azure-sandbox",
    "audiences": ["api://AzureADTokenExchange"]
  }'
```

The `subject` must match the run exactly. Use
`repo:<owner>/<repo>:ref:refs/heads/main` instead if you prefer to bind to a
branch. Never use a wildcard subject: it would authorize any branch, including
one pushed by anyone with write access.

### 3. Publish the identity as repository variables

These three values are identifiers, not secrets, so they are variables:

```bash
gh variable set ARM_CLIENT_ID       --body "${ARM_CLIENT_ID}"
gh variable set ARM_TENANT_ID       --body "${ARM_TENANT_ID}"
gh variable set ARM_SUBSCRIPTION_ID --body "${ARM_SUBSCRIPTION_ID}"
```

Do **not** create an `ARM_CLIENT_SECRET` secret. The workflow fails on purpose
if one is present, because its presence would make the run prove nothing.

### 4. Grant the Service Principal cluster access

Only needed for the optional `cluster-access` job, and a prerequisite for
moving the `kubernetes` and `helm` providers off `kube_admin_config`.

`src/cluster` sets `azure_rbac_enabled = true` and
`admin_group_object_ids = var.administrators_ids`, which resolves to the
`aks-administrator` group. Adding the Service Principal to that group grants
cluster-admin at cluster creation time, with no role assignment and no
propagation race:

```bash
az ad group member add \
  --group d5075d0a-3704-4ed9-ad62-dc8068c7d0e1 \
  --member-id "$(az ad sp show --id "${ARM_CLIENT_ID}" --query id --output tsv)"
```

Group membership travels inside the token. A token issued before the change
does not see the new group; run `az account clear` locally, or simply start a
new CI job.

### 5. Run it

```bash
gh workflow run azure-oidc-federation.yml

# optionally exercise non-admin access against a live cluster
gh workflow run azure-oidc-federation.yml \
  --field cluster_name=wasp-sandbox-9f5ed
```

| Step | What it proves |
| --- | --- |
| `Refuse to run if a client secret is present` | the run cannot be passing for the wrong reason |
| `Azure login` + `az account show` | the OIDC exchange succeeded and resolved to the expected Service Principal |
| `az group list` | the federated token carries real ARM permissions |
| `kubelogin --version` | the binary needed by the `exec` provider auth is installable in CI |
| `terraform validate` | the example still parses with the pinned provider versions |
| `kubectl auth can-i '*' '*'` | the Service Principal is cluster-admin through Entra ID, not through the local admin account |

### Terraform authentication once federation is proven

With federation in place the provider and the backend both drop their secrets:

| Variable | Value in CI |
| --- | --- |
| `ARM_USE_OIDC` | `true` |
| `ARM_CLIENT_ID` / `ARM_TENANT_ID` / `ARM_SUBSCRIPTION_ID` | repository variables |
| `ARM_CLIENT_SECRET` | **unset** |
| `ARM_SAS_TOKEN` | **unset** — the `azurerm` backend also accepts `use_oidc = true` |

Note that [`stack.yaml`](stack.yaml) still declares Terraform `1.9.2`, while
the istio example is validated on `1.14.8` and requires `>= 1.9.0`. Reconcile
the two before wiring a real `plan`/`apply` pipeline.

### Troubleshooting

| Error | Cause |
| --- | --- |
| `AADSTS70021: No matching federated identity record found` | the `subject` in the federated credential does not match the run (branch vs. environment, wrong repo name) |
| `Unable to get ACTIONS_ID_TOKEN_REQUEST_URL` | the job is missing `permissions: id-token: write` |
| OIDC token not issued at all | the run came from a fork pull request; GitHub does not issue `id-token` for those |

## Assumptions

The examples will assume `subscriptions` names like:

```lua
${local.project}-${local.environment}
wasp-sandbox
wasp-dev
```

The default domain for the examples is: `silvios.me`.

When an AKS Cluster is created and configured with ArgoCD, a Gateway URL will be created like:

```lua
DNS Zone..............:                             ${local.environment}.${local.project}.${local.domain} ->               sandbox.wasp.silvios.me
DNS Zone A Record.....: gateway.${random_string.id}.${local.environment}.${local.project}.${local.domain} -> gateway.xpt54.sandbox.wasp.silvios.me -> Load Balancer/Public IP
DNS Zone CNAME Record.:  argocd.${random_string.id}.${local.environment}.${local.project}.${local.domain} ->  argocd.xpt54.sandbox.wasp.silvios.me -> gateway.xpt54.sandbox.wasp.silvios.me
```

Please take a look on [variables.tf](examples/common/variables.tf).

## Environment Variables

| Variable                                            | Description                                           | Example                                                              |
| --------------------------------------------------- | ----------------------------------------------------- | -------------------------------------------------------------------- | 
| `ARM_TENANT_ID`                                     | Azure Tenant ID                                       | `b55fd5d1-eb1b-4a04-a3a9-6b703924c36b`                               |
| `ARM_SUBSCRIPTION_ID`                               | Azure Subscription ID                                 | `636a465c-d6b1-4533-b071-64cea37a2bf6`                               |
| `ARM_CLIENT_ID`                                     | Azure Service Principal ID                            | `74cbe1b4-4112-415f-9aaf-be300a89c170`                               |
| `ARM_CLIENT_SECRET`                                 | Azure Service Principal Secret                        | `TWY7Q~*******************************`                              |

In CI, `ARM_CLIENT_SECRET` is replaced by OIDC federation — see
[GitHub Actions OIDC Federation (CI)](#github-actions-oidc-federation-ci).

## Secrets 

| Secret                                              | Description                                           | Example                                                              |
| --------------------------------------------------- | ----------------------------------------------------- | -------------------------------------------------------------------- | 
| `argocd-repo-creds-ssh-private-key-base64-encoded`  | SSH Private Key Base 64 Encode (without line breaks)  | `LS0tLS1CRUdJTiBPUEVOU1NIIFBSSVZBVEUgS0VZLS0tLS0KYjNCbGJuTnphQzF...` |
| `argocd-repo-creds-url-ado`                         | Credential Template URL for Azure DevOps Project      | `git@ssh.dev.azure.com:v3/smsilva/azure-platform/`                   |
| `argocd-repo-creds-url-github`                      | Credential Template URL for GitHub                    | `git@github.com:smsilva/`                                            |
| `new-relic-license-key`                             | New Relic License Key                                 | `157629bec2**************************NRAL`                           |

# Application Gateway Example Execution

```bash
cd examples/cluster_argocd_ingress_nginx

terraform init

terraform plan

terraform apply
```

# Provisioning Time Estimates

Measured on `examples/cluster_argocd_ingress_istio` (azurerm v5.2 / helm v3.2 /
AKS 1.35.7), full stack from scratch, 35 resources, region `eastus2`,
`install_app_of_apps_infra = false`. Helm release durations come from
Terraform's `Creation complete after`; parallel modules overlap, so the total
is **not** the sum of the rows.

| Step                                    | Duration      | Notes                                              |
| --------------------------------------- | ------------- | -------------------------------------------------- |
| Resource Group + VNet/subnets           | ~15s          | fast Azure control-plane ops                       |
| Managed identities + app registration   | ~10s          | 2 UAMIs, federated credentials come after the AKS  |
| AKS cluster (control plane + nodepool)  | 3m29s         | dominant cost; varies with region/load             |
| Role assignments (kubelet, DNS, RBAC)   | ~25s each     | created in parallel                                |
| cert-manager (v1.21.1, helm)            | 1m40s         | includes CRDs                                      |
| cert-manager-issuers (helm)             | 7s            |                                                    |
| external-secrets (ESO 2.9.0, helm)      | 1m37s         | + Workload Identity federated credential           |
| external-secrets-config (helm)          | 4s            | `ClusterSecretStore`                               |
| external-dns (0.21.0, helm)             | 39s           | + `external-dns-config` 6s                         |
| ingress-istio (helm, 1.30.3)            | 20s/28s/38s   | `istio-base` / `istio-discovery` / `istio-gateway` |
| httpbin (helm)                          | 2m30s         | waits for Gateway + cert readiness                 |
| argo-cd 10.4.0 / v3.5.1 (helm)          | 2m35s         | `atomic=true`, waits all 7 pods ready              |
| argo-cd-config (helm)                   | 3s            | idle on istio (azure/nginx subcharts disabled)     |
| **Full `terraform apply` (wall-clock)** | **~9min**     | AKS provisioning dominates; helm stage overlaps    |

> Measured 2026-08-22 on cluster `wasp-sandbox-9f5ed`. Enabling
> `install_app_of_apps_infra` adds one more helm release plus the ArgoCD sync
> time of the external GitOps repo.

# Follow Process

```bash
# wasp-xpt3
watch -n 10 'scripts/follow-creation/follow xpt3'
```

# Helm Charts

| Name              | URL                                                                     |
| ----------------- | ----------------------------------------------------------------------- |
| argo              | https://argoproj.github.io/argo-helm                                    |
| cert-manager      | https://charts.jetstack.io                                              |
| external-dns      | https://kubernetes-sigs.github.io/external-dns                          |
| external-secrets  | https://charts.external-secrets.io                                      |
| ingress-azure     | https://appgwingress.blob.core.windows.net/ingress-azure-helm-package   |
| ingress-nginx     | https://kubernetes.github.io/ingress-nginx                              |
| istio             | https://istio-release.storage.googleapis.com/charts                     |

## Ingress Azure

```bash
helm fetch oci://mcr.microsoft.com/azure-application-gateway/charts/ingress-azure \
  --untar \
  --untardir src/helm/charts/ingress-azure
```
