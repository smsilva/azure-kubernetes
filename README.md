# azure-kubernetes

Terraform modules that provision AKS with a GitOps stack (ArgoCD) and a choice
of ingress (Istio, NGINX, Application Gateway).

- [`src/`](src/) — reusable modules, **shared by every example**
- [`examples/`](examples/) — 5 examples consuming `src/`; `cluster_argocd_ingress_istio`
  is the maintained one
- [`scripts/`](scripts/) — bootstrap and follow-along utilities
- [`docs/reference/`](docs/reference/) — per-topic operational knowledge

## Prerequisites

- Azure Subscription
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

## CI Bootstrap

CI authenticates to Azure through workload identity federation — no client
secret is ever stored in this (public) repository. Founding a new environment
is one idempotent command:

```bash
scripts/ci-bootstrap --dry-run

scripts/ci-bootstrap \
  --repository smsilva/azure-kubernetes \
  --environment azure-sandbox
```

It composes the Azure, GitHub, and Entra ID steps: federated credential,
environment variables, per-repository SSH deploy keys, and the two directory
role grants. Verify the result with:

```bash
gh workflow run azure-oidc-federation.yml
```

→ Full setup, per-script breakdown, what the proof workflow checks, and
troubleshooting: [`docs/ci-oidc-federation.md`](docs/ci-oidc-federation.md).

## Running an Example

```bash
cd examples/cluster_argocd_ingress_istio

terraform init

terraform plan

terraform apply
```

After a successful `apply`, `terraform output` returns the cluster name,
resource group, and the Gateway/ArgoCD/httpbin URLs — see
[`outputs.tf`](examples/cluster_argocd_ingress_istio/outputs.tf).

A full run takes **~9 minutes**, dominated by AKS provisioning. To watch it
stage by stage:

```bash
watch -n 10 'scripts/follow-creation/follow xpt3'
```

→ Per-step timings: [`docs/provisioning-time.md`](docs/provisioning-time.md).

## Assumptions

The examples assume `subscriptions` names like:

```lua
${local.project}-${local.environment}
wasp-sandbox
wasp-dev
```

The default domain for the examples is `silvios.me`.

When an AKS cluster is created and configured with ArgoCD, a Gateway URL is
created like:

```lua
DNS Zone..............:                             ${local.environment}.${local.project}.${local.domain} ->               sandbox.wasp.silvios.me
DNS Zone A Record.....: gateway.${random_string.id}.${local.environment}.${local.project}.${local.domain} -> gateway.xpt54.sandbox.wasp.silvios.me -> Load Balancer/Public IP
DNS Zone CNAME Record.:  argocd.${random_string.id}.${local.environment}.${local.project}.${local.domain} ->  argocd.xpt54.sandbox.wasp.silvios.me -> gateway.xpt54.sandbox.wasp.silvios.me
```

See [variables.tf](examples/common/variables.tf).

## Environment Variables

| Variable              | Description                    | Example                                  |
| --------------------- | ------------------------------ | ---------------------------------------- |
| `ARM_TENANT_ID`       | Azure Tenant ID                | `b55fd5d1-eb1b-4a04-a3a9-6b703924c36b`   |
| `ARM_SUBSCRIPTION_ID` | Azure Subscription ID          | `636a465c-d6b1-4533-b071-64cea37a2bf6`   |
| `ARM_CLIENT_ID`       | Azure Service Principal ID     | `74cbe1b4-4112-415f-9aaf-be300a89c170`   |
| `ARM_CLIENT_SECRET`   | Azure Service Principal Secret | `TWY7Q~*******************************`  |

In CI, `ARM_CLIENT_SECRET` is replaced by OIDC federation — see
[`docs/ci-oidc-federation.md`](docs/ci-oidc-federation.md).

## Secrets

| Secret                                             | Description                                          | Example                                                              |
| -------------------------------------------------- | ---------------------------------------------------- | -------------------------------------------------------------------- |
| `argocd-repo-creds-ssh-private-key-base64-encoded` | SSH Private Key Base 64 Encode (without line breaks) | `LS0tLS1CRUdJTiBPUEVOU1NIIFBSSVZBVEUgS0VZLS0tLS0KYjNCbGJuTnphQzF...` |
| `argocd-repo-creds-url-ado`                        | Credential Template URL for Azure DevOps Project     | `git@ssh.dev.azure.com:v3/smsilva/azure-platform/`                   |
| `argocd-repo-creds-url-github`                     | Credential Template URL for GitHub                   | `git@github.com:smsilva/`                                            |
| `new-relic-license-key`                            | New Relic License Key                                | `157629bec2**************************NRAL`                           |

## Helm Charts

| Name              | URL                                                                     |
| ----------------- | ----------------------------------------------------------------------- |
| argo              | https://argoproj.github.io/argo-helm                                    |
| cert-manager      | https://charts.jetstack.io                                              |
| external-dns      | https://kubernetes-sigs.github.io/external-dns                          |
| external-secrets  | https://charts.external-secrets.io                                      |
| ingress-azure     | https://appgwingress.blob.core.windows.net/ingress-azure-helm-package   |
| ingress-nginx     | https://kubernetes.github.io/ingress-nginx                              |
| istio             | https://istio-release.storage.googleapis.com/charts                     |

### Ingress Azure

```bash
helm fetch oci://mcr.microsoft.com/azure-application-gateway/charts/ingress-azure \
  --untar \
  --untardir src/helm/charts/ingress-azure
```
