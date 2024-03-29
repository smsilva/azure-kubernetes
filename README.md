# Prerequisites

- Azure Subscrition
- Azure Service Principal
- Azure Key Vault
- Azure DNS Zone

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
