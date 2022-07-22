# Prerequisites

| Secret                                             | Description                                             | Example                                                              |
| -------------------------------------------------- | ------------------------------------------------------- | -------------------------------------------------------------------- | 
| `argocd-oidc-azuread-client-secret`                | Active Directory ArgoCD App Registration Client Secret  | `LkuxT*****************************`                                 |
| `argocd-repo-creds-base64-encoded-private-key-ado` | Azure DevOps Base64 Encode SSH Private Key              | `LS0tLS1CRUdJTiBPUEVOU1NIIFBSSVZBVEUgS0VZLS0tLS0KYjNCbGJuTnphQzF...` |
| `argocd-repo-creds-url-ado`                        | ArgoCD Credential Template URL for Azure DevOps Project | `git@github.com:smsilva/wasp-gitops.git`                    |
| `new-relic-license-key`                            | New Relic License Key                                   | `157629bec2854d7aa8d65d0d5f5ed18b4d7aa8d6`                           |

# Image Build

```bash
stackbuild .
```

# Follow Process

```bash
watch -n 10 'scripts/follow-creation.sh'
```

# Cleanup

```bash
kubectl delete namespace {argocd,cert-manager,external-secrets,ingress-azure}
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
