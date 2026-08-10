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

Measured on `examples/cluster_argocd_ingress_istio` (azurerm v5 / helm v3 /
AKS 1.34.9), full stack from scratch (`install_*` all `true`, 35 resources).
Helm release durations are from Terraform's `Creation complete after`; parallel
modules overlap, so the total is **not** the sum of the rows.

| Step                                  | Duration | Notes                                              |
| ------------------------------------- | -------- | -------------------------------------------------- |
| Resource Group + VNet/subnets         | ~30s     | fast Azure control-plane ops                       |
| AKS cluster (control plane + nodepool)| ~8–12min | dominant cost; varies with region/load             |
| cert-manager (helm)                   | ~1min    | includes CRDs                                      |
| external-secrets (ESO 2.9.0, helm)    | ~1min    | + Workload Identity federated credential           |
| external-dns (helm)                   | ~30s     |                                                    |
| ingress-istio (istio-gateway, helm)   | ~40s     | base/istiod/gateway subcharts 1.30.3               |
| httpbin (helm)                        | ~2m20s   | waits for Gateway + cert readiness (`atomic`)      |
| argo-cd 10.3.2 (helm)                 | ~2m30s   | `atomic=true`, waits all 7 pods ready              |
| argo-cd-config (helm)                 | ~3s      | idle on istio (azure/nginx subcharts disabled)     |
| **Full `terraform apply` (wall-clock)** | **~15–20min** | AKS provisioning dominates; helm stage overlaps |

> Rows with `~min` for AKS/RG are approximate — the captured apply log was
> truncated to the helm stage. Refine these on the next full run.

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
