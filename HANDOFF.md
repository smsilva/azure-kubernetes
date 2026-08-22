# HANDOFF

## Why

Entregar um cluster Kubernetes **na AWS (EKS)** equivalente ao que este repositório provisiona hoje no Azure (`examples/cluster_argocd_ingress_istio`: AKS 1.34.9 + cert-manager + external-secrets + external-dns + ingress-istio + httpbin + ArgoCD + app-of-apps), porém provisionado com **Crossplane** em vez de Terraform. Fluxo alvo: Crossplane provisiona o EKS; uma vez pronto, instalar os helm charts nele. Objetivo: resultado similar — de preferência igual em capacidades — mas usando recursos AWS.

Usar este repo Azure como **referência funcional** (o que o cluster final precisa entregar), traduzindo cada peça para o equivalente AWS. Começar pela **skill de brainstorming do plugin oficial da Anthropic** para desenhar a abordagem antes de escrever manifestos.

**Snapshot do estado-alvo:** `~/trash/resources/aks-poc/` (persistente, sobrevive a reinício) tem o dump JSON de todos os recursos Azure + estado k8s do cluster de referência `wasp-sandbox-vpd54`. Ler o `CLAUDE.md` e o `README.md` dessa pasta — cada arquivo mapeia para o equivalente AWS. É a fonte de verdade do que o EKS precisa atingir, mesmo depois de o cluster Azure ser destruído.

## Mapa de tradução Azure → AWS (a validar no brainstorming)

- AKS → **EKS**; nodepool → managed node group / Karpenter.
- Managed Identity + Federated Credential (Workload Identity) → **IRSA** (IAM Roles for Service Accounts) via OIDC provider do EKS.
- Azure Key Vault (backend do external-secrets) → **AWS Secrets Manager** ou SSM Parameter Store; `ClusterSecretStore` do ESO muda de provider `azurekv` para `aws`.
- Azure DNS Zone (external-dns) → **Route 53**; role do external-dns via IRSA com policy de Route53.
- Azure App Registration (SSO azuread do ArgoCD) → **AWS Cognito** ou IdP OIDC externo (definir; azuread pode continuar como IdP se desejado).
- Load Balancer público do istio-ingress → **NLB/ALB** via AWS Load Balancer Controller.
- cert-manager, ingress-istio, httpbin, argo-cd, app-of-apps → em tese portáveis (só mudam issuers/DNS/secret backend).

## In Progress

Referência Azure (Terraform) validada end-to-end. Próximo passo pretendido: iniciar o brainstorming Crossplane+AWS (escolha de provider, cluster de management, IRSA, backend de secrets AWS, DNS Route53).

> Existe um segundo workstream em `HANDOFF.local.md` (pessoal, não versionado): review de melhorias do `examples/cluster_argocd_ingress_istio`, com 8 achados ainda em aberto (SSO do ArgoCD aceitando contas Microsoft pessoais, credencial admin no state, redirect HTTP→HTTPS que nunca dispara, entre outros).

## Estado da referência Azure (cluster `wasp-sandbox-vpd54`)

- **DESTRUÍDO** — o cluster `wasp-sandbox-vpd54` não existe mais (verificado 2026-08-22: nenhum AKS na subscription `wasp-sandbox`). O snapshot em `~/trash/resources/aks-poc/` continua sendo a fonte de verdade do estado-alvo. Números abaixo descrevem como ele era.
- Stack validada: ArgoCD chart 10.3.2 (UI HTTP 200, SSO azuread ok), ingress-istio 1.30.3, cert-manager (3 certs `READY=True`, LE staging), external-dns escrevendo na zona via Workload Identity, httpbin HTTP 200.
- app-of-apps-infra `Synced`; Applications: `app-of-apps-infra`, `namespaces`, `nri-bundle`, `nri-bundle-foundation` todas `Synced` (`nri-bundle` pode ficar `Progressing` enquanto o DaemonSet New Relic sobe).
- Fixes desta sessão: (1) `src/helm/modules/argo-cd/templates/extra-objects.yaml` ExternalSecret v1beta1→v1; (2) repo externo `wasp-gitops` branch `dev`, `infrastructure/charts/nri-bundle-foundation/templates/external-secret.yaml` v1alpha1→v1; (3) chave SSH no Key Vault (`argocd-repo-creds-ssh-private-key-base64-encoded`) trocada para `~/.ssh/id_rsa_personal`.

## Open Questions / Hypotheses

- Crossplane: `provider-upjet-aws` (Upbound) vs. provider AWS nativo? EKS + node group + OIDC + IRSA roles + Route53 precisam existir como managed resources.
- Onde roda o control plane do Crossplane: cluster de management separado é necessário para provisionar o EKS (bootstrap). Definir se é kind local, EKS pré-existente, ou outro.
- IRSA end-to-end: OIDC provider do EKS → IAM role com trust policy no SA → anotação `eks.amazonaws.com/role-arn` no SA. Substitui toda a lógica de Workload Identity do Azure (external-secrets e external-dns dependem disso).
- Backend de secrets: Secrets Manager vs. SSM Parameter Store para o `ClusterSecretStore`. Onde ficam os repo-creds SSH do ArgoCD e o clientSecret do SSO.
- SSO do ArgoCD na AWS: manter azuread como IdP OIDC ou trocar por Cognito.
- Instalação dos charts após o EKS pronto: `provider-helm` do Crossplane vs. delegar ao ArgoCD app-of-apps (como já é feito no Azure).

## Known Broken

- **Ambiente Azure `vpd54`** — já destruído. Um cluster equivalente pode ser recriado em ~9min com `terraform apply` no exemplo istio (ver tempos medidos no `README.md`).
- **Exemplo `cluster_argocd_ingress_nginx`** — *inesperado*: além do provider desatualizado, não passa `identity_client_id` (variável obrigatória) ao módulo `external-dns`, então falha já no `plan`. O modo kubelet de auth do external-dns não existe mais no repo (o chart `external-dns-config` fixa `useWorkloadIdentityExtension: true`), logo migrar esse exemplo exige criar uma MI federada para ele.
- **Outros 4 exemplos Terraform Azure** — *intencional*: quebrados pelos módulos compartilhados já em azurerm v5/helm v3. Não usar como referência sem migrar.
- **Chart `ingress-azure` removido** — *inesperado*: só afeta o exemplo azure Terraform; irrelevante para AWS.

## How to Resume

Iniciar o brainstorming da abordagem Crossplane + AWS (EKS):

```bash
# invocar a skill de brainstorming do plugin oficial da Anthropic
# tema: provisionar EKS equivalente ao examples/cluster_argocd_ingress_istio (Azure) via
#       Crossplane, depois instalar os helm charts (cert-manager, external-secrets sobre
#       Secrets Manager, external-dns sobre Route53, ingress-istio, httpbin, argo-cd,
#       app-of-apps). Usar o Mapa de tradução Azure→AWS acima como ponto de partida.
```

Snapshot do estado-alvo (persistente, disponível mesmo após destruir o Azure):

```bash
cat ~/trash/resources/aks-poc/CLAUDE.md   # como usar e por quê
cat ~/trash/resources/aks-poc/README.md   # índice arquivo → equivalente AWS
```

Referência viva Azure: o cluster `vpd54` não existe mais. Para recriar um equivalente
(~9min), rodar `terraform apply` em `examples/cluster_argocd_ingress_istio` — o exemplo
tem README próprio com validação e gotchas. Quem estiver com um cluster de pé descreve
qual é em `HANDOFF.local.md`.

## Next Steps

1. Rodar a skill de brainstorming (plugin oficial Anthropic): arquitetura Crossplane+AWS, escolha de provider, cluster de management, mapa recurso-a-recurso (validar/expandir o Mapa de tradução acima), estratégia de instalação dos charts.
2. Definir MVP walk skeleton: provisionar só o EKS via Crossplane, validar acesso kubectl, depois adicionar charts incrementalmente — um de cada vez, espelhando a estratégia usada no Azure.
3. Resolver IRSA (OIDC provider + IAM roles + SA annotations) — pré-requisito de external-secrets e external-dns na AWS.
4. Escolher backend de secrets AWS (Secrets Manager/SSM) e reapontar o `ClusterSecretStore` do ESO.
5. Decidir SSO do ArgoCD (azuread OIDC vs. Cognito) e DNS (Route53 + external-dns).
6. Recriar o exemplo istio no Azure sob demanda (~9min) sempre que precisar comparar comportamento com o EKS, em vez de manter um cluster Azure permanente.

> Before trusting anything time-sensitive above, run `git status`, `git diff`, and `git log` against the base branch.