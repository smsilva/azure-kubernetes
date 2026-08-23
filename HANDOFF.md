# HANDOFF

## Why

Entregar um cluster Kubernetes na **AWS (EKS)** equivalente ao que este repo
provisiona no Azure (`examples/cluster_argocd_ingress_istio`), porém via
**Crossplane** em vez de Terraform. Este repo é a referência funcional: o que o
cluster final precisa entregar.

Insumos: `docs/aws-eks-translation-map.md` (mapa recurso-a-recurso, questões em
aberto, snapshot do estado-alvo em `~/trash/resources/aks-poc/`).

## In Progress

Nada. Referência Azure validada end-to-end e **destruída** — nenhum cluster AKS na
subscription `wasp-sandbox`. Recriar equivalente em ~9min com `terraform apply` no
exemplo istio.

> Segundo workstream (pessoal) em `HANDOFF.local.md`.

## Known Broken

- 4 exemplos Terraform legado quebrados pelos módulos compartilhados —
  **intencional**, ver `docs/reference/provider-migration.md`.

## How to Resume

Iniciar o brainstorming Crossplane + AWS (skill `superpowers:brainstorming`), tema:
provisionar EKS equivalente ao exemplo istio e instalar os charts (cert-manager,
external-secrets sobre Secrets Manager, external-dns sobre Route53, ingress-istio,
httpbin, argo-cd, app-of-apps).

```bash
cat ~/trash/resources/aks-poc/README.md   # índice arquivo → equivalente AWS
```

## Next Steps

1. Brainstorming: arquitetura Crossplane+AWS, escolha de provider, cluster de
   management, validar o mapa de tradução.
2. MVP walk skeleton: só o EKS via Crossplane + acesso kubectl; charts incrementais.
3. IRSA (OIDC provider + IAM roles + SA annotations) — pré-requisito de
   external-secrets e external-dns.
4. Escolher backend de secrets AWS e reapontar o `ClusterSecretStore`.
5. Decidir SSO do ArgoCD (azuread OIDC vs. Cognito) e DNS (Route53).

> Antes de confiar em algo time-sensitive acima: `git status`, `git diff`, `git log`.
