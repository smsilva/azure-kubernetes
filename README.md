# Prerequisites

- Azure Subscrition
- Azure Service Principal
- Azure Key Vault
- Azure DNS Zone

## Environment Variables

| Variable                                           | Description                                             | Example                                                              |
| -------------------------------------------------- | ------------------------------------------------------- | -------------------------------------------------------------------- | 
| `ARM_TENANT_ID`                                    | Azure Tenant ID                                         | `b55fd5d1-eb1b-4a04-a3a9-6b703924c36b`                               |
| `ARM_SUBSCRIPTION_ID`                              | Azure Subscription ID                                   | `636a465c-d6b1-4533-b071-64cea37a2bf6`                               |
| `ARM_CLIENT_ID`                                    | Azure Service Principal ID                              | `74cbe1b4-4112-415f-9aaf-be300a89c170`                               |
| `ARM_CLIENT_SECRET`                                | Azure Service Principal Secret                          | `TWY7Q~*******************************`                              |

## Secrets

| Secret                                             | Description                                             | Example                                                              |
| -------------------------------------------------- | ------------------------------------------------------- | -------------------------------------------------------------------- | 
| `argocd-oidc-azuread-client-secret`                | Active Directory ArgoCD App Registration Client Secret  | `LkuxT*****************************`                                 |
| `argocd-repo-creds-base64-encoded-private-key-ado` | Azure DevOps Base64 Encode SSH Private Key              | `LS0tLS1CRUdJTiBPUEVOU1NIIFBSSVZBVEUgS0VZLS0tLS0KYjNCbGJuTnphQzF...` |
| `argocd-repo-creds-url-ado`                        | ArgoCD Credential Template URL for Azure DevOps Project | `git@github.com:smsilva/wasp-gitops.git`                             |
| `new-relic-license-key`                            | New Relic License Key                                   | `157629bec2854d7aa8d65d0d5f5ed18b4d7aa8d6`                           |

# Application Gateway Example

```bash
cd azure-kubernetes/examples/cluster_with_argocd_ingress_azure

terraform init

terraform plan

terraform apply
```

# Follow Process

```bash
watch -n 10 'scripts/follow-creation.sh'
```

# Helm Charts

| Name              | URL                                                                     |
| ----------------- | ----------------------------------------------------------------------- |
| aad-pod-identity  | https://raw.githubusercontent.com/Azure/aad-pod-identity/master/charts  |
| argo-cd           | https://argoproj.github.io/argo-helm                                    |
| cert-manager      | https://charts.jetstack.io                                              |
| external-dns      | https://kubernetes-sigs.github.io/external-dns                          |
| external-secrets  | https://charts.external-secrets.io                                      |
| ingress-azure     | https://appgwingress.blob.core.windows.net/ingress-azure-helm-package   |
| ingress-nginx     | https://kubernetes.github.io/ingress-nginx                              |
