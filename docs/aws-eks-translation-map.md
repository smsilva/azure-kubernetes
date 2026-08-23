# Mapa de tradução Azure → AWS

Insumo para o workstream "EKS via Crossplane equivalente ao
`examples/cluster_argocd_ingress_istio`". A validar/expandir no brainstorming.

| Azure (hoje) | AWS (alvo) |
|---|---|
| AKS | EKS |
| nodepool | managed node group ou Karpenter |
| Managed Identity + Federated Credential (Workload Identity) | IRSA via OIDC provider do EKS |
| Azure Key Vault (backend do external-secrets) | Secrets Manager ou SSM Parameter Store (`ClusterSecretStore` `azurekv` → `aws`) |
| Azure DNS Zone (external-dns) | Route 53 (role via IRSA com policy de Route53) |
| App Registration (SSO azuread do ArgoCD) | Cognito ou manter azuread como IdP OIDC |
| Load Balancer público do istio-ingress | NLB/ALB via AWS Load Balancer Controller |
| cert-manager, ingress-istio, httpbin, argo-cd, app-of-apps | portáveis (mudam issuers/DNS/secret backend) |

## Snapshot do estado-alvo

`~/trash/resources/aks-poc/` (persistente) tem o dump JSON de todos os recursos Azure
+ estado k8s do cluster de referência `wasp-sandbox-vpd54`, já destruído. Ler o
`CLAUDE.md` e o `README.md` dessa pasta — cada arquivo mapeia para o equivalente AWS.
É a fonte de verdade do que o EKS precisa atingir.

## Capacidades que o cluster final precisa entregar

AKS 1.34.9 + cert-manager + external-secrets + external-dns + ingress-istio + httpbin
+ ArgoCD + app-of-apps. Referência validada end-to-end: ArgoCD chart 10.3.2 (UI 200,
SSO ok), ingress-istio 1.30.3, cert-manager com certs `READY=True` (LE staging),
external-dns escrevendo na zona via Workload Identity, httpbin 200, app-of-apps-infra
`Synced`.

## Questões em aberto

- Crossplane: `provider-upjet-aws` (Upbound) vs. provider AWS nativo?
- Onde roda o control plane do Crossplane (kind local, EKS pré-existente, outro)?
- Backend de secrets: Secrets Manager vs. SSM para o `ClusterSecretStore`.
- SSO do ArgoCD: manter azuread como IdP OIDC ou trocar por Cognito.
- Instalação dos charts após o EKS pronto: `provider-helm` vs. delegar ao ArgoCD
  app-of-apps (como já é feito no Azure).
