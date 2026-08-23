# Azure → AWS translation map

Input for the "EKS via Crossplane equivalent to
`examples/cluster_argocd_ingress_istio`" workstream. To be validated/expanded
during brainstorming.

| Azure (today) | AWS (target) |
|---|---|
| AKS | EKS |
| nodepool | managed node group or Karpenter |
| Managed Identity + Federated Credential (Workload Identity) | IRSA via the EKS OIDC provider |
| Azure Key Vault (external-secrets backend) | Secrets Manager or SSM Parameter Store (`ClusterSecretStore` `azurekv` → `aws`) |
| Azure DNS Zone (external-dns) | Route 53 (role via IRSA with a Route53 policy) |
| App Registration (ArgoCD azuread SSO) | Cognito, or keep azuread as the OIDC IdP |
| Public Load Balancer of istio-ingress | NLB/ALB via the AWS Load Balancer Controller |
| cert-manager, ingress-istio, httpbin, argo-cd, app-of-apps | portable (issuers/DNS/secret backend change) |

## Snapshot of the target state

`~/trash/resources/aks-poc/` (persistent) holds the JSON dump of every Azure
resource plus the k8s state of the reference cluster `wasp-sandbox-vpd54`, now
destroyed. Read that folder's `CLAUDE.md` and `README.md` — each file maps to its
AWS equivalent. It is the source of truth for what the EKS has to achieve.

## Capabilities the final cluster must deliver

AKS 1.34.9 + cert-manager + external-secrets + external-dns + ingress-istio +
httpbin + ArgoCD + app-of-apps. Reference validated end-to-end: ArgoCD chart
10.3.2 (UI 200, SSO ok), ingress-istio 1.30.3, cert-manager with certificates
`READY=True` (LE staging), external-dns writing to the zone via Workload
Identity, httpbin 200, app-of-apps-infra `Synced`.

## Open questions

- Crossplane: `provider-upjet-aws` (Upbound) vs. the native AWS provider?
- Where does the Crossplane control plane run (local kind, a pre-existing EKS,
  something else)?
- Secrets backend: Secrets Manager vs. SSM for the `ClusterSecretStore`.
- ArgoCD SSO: keep azuread as the OIDC IdP or switch to Cognito.
- Installing the charts once the EKS is ready: `provider-helm` vs. delegating to
  the ArgoCD app-of-apps (as already done on Azure).
