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
watch -n 4 '
helm list -A && echo && \
kubectl get ExternalSecrets -A | head -n 8 && echo && \
kubectl get Ingress -A | head -n 5 && echo && \
kubectl -n argocd get Applications,Statefulsets | grep -E "NAME|bootstrap|infra|bar|nri" && echo && \
ARGOCD_HOST=$(kubectl \
  -n argocd get ingress \
  -l app.kubernetes.io/name=argocd-server \
  -o jsonpath='{.items[0].spec.rules[0].host}') && \
echo "https://${ARGOCD_HOST}: $(curl -Is https://${ARGOCD_HOST} | head -1)"
'
```

# Cleanup

```bash
kubectl delete namespace {argocd,cert-manager,external-secrets,ingress-azure}
```
