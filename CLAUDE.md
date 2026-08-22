# azure-kubernetes

Repositório de módulos Terraform para provisionar AKS com stack GitOps (ArgoCD) e opções de ingress (Istio, NGINX, Application Gateway).

## Estrutura

- `src/` — módulos Terraform reutilizáveis (compartilhados entre exemplos)
  - `src/cluster` — `azurerm_kubernetes_cluster` + role assignments
  - `src/nodepool` — `azurerm_kubernetes_cluster_node_pool` adicional
  - `src/active-directory/app-registration` — `azuread_application` para SSO do ArgoCD
  - `src/application-gateway` — ingress via Azure Application Gateway
  - `src/helm/modules/*` — wrappers `helm_release` (cert-manager, external-secrets, external-dns, ingress-istio, ingress-nginx, ingress-azure, httpbin, argo-cd, app-of-apps-infra)
  - `src/helm/charts/*` — charts locais (vendored via `helm fetch`)
- `examples/` — 5 exemplos que consomem os módulos de `src/`
- `examples/common/` — arquivos compartilhados por symlink (`variables.tf`, `secrets.tf`, `network.tf`)
- `scripts/` — utilitários (ver `scripts/update-local-helm-charts` e `scripts/update-local-helm-charts-istio`)

## ⚠️ Módulos compartilhados vs. versões de provider por exemplo

`src/cluster`, `src/nodepool` e `src/helm/modules/*` são **compartilhados** pelos 5 exemplos, mas cada exemplo pina uma versão diferente de provider. **Editar um módulo compartilhado afeta todos os exemplos.**

| Exemplo | azurerm | helm | Estado |
|---|---|---|---|
| `cluster_argocd_ingress_istio` | **>= 5.0** | **>= 3.0** | migração em andamento |
| `cluster_argocd_ingress_azure` | >= 4.0 | >= 3.0 | migração parcial anterior |
| `cluster_argocd_ingress_nginx` | >= 3.0 | (sem pin) | legado |
| `cluster_one_nodepool` | >= 3.0 | — | legado |
| `cluster_two_nodepools` | >= 3.0 | — | legado (usa `src/nodepool`) |

**Incompatibilidades conhecidas ao migrar módulos compartilhados:**
- `node_provisioning_profile` (bloco em `src/cluster/main.tf`) **só existe no azurerm v5** → quebra os exemplos v3/v4.
- Renomeações no `src/nodepool` (`auto_scaling_enabled`, `node_public_ip_enabled`, `host_encryption_enabled`) são **v4+** → quebram exemplos v3.
- Sintaxe helm `set = [...]` (lista de objetos) é **v3**; `set {...}` (bloco) é **v2**. Não misturar no mesmo módulo.
- No helm provider v3, o `provider "helm"` usa `kubernetes = {...}` (atributo), não `kubernetes {...}` (bloco).
- `azurerm_federated_identity_credential` no v5 usa `user_assigned_identity_id`; NÃO aceita `parent_id` nem `resource_group_name`.
- Labels de pod via helm `set` precisam `type = "string"` (ex.: `azure.workload.identity/use = "true"`), senão o helm infere boolean e o k8s rejeita o label.

## Gotchas operacionais

- `scripts/update-local-helm-charts` NÃO é só checagem: faz `rm -rf` + `helm fetch --untar` e **substitui** os charts locais quando a versão remota difere. Rodar só quando quiser de fato atualizar.
- O helm provider não detecta mudança quando só o **conteúdo do chart local** muda (mesmos `values`/`set`). Forçar com `terraform apply -replace='module.<mod>[0].helm_release.<release>'`.
- Acesso kubectl sem `kubelogin`: usar admin config → `az aks get-credentials --resource-group <rg> --name <cluster> --admin --overwrite-existing`.
- O SP do Terraform precisa de `User Access Administrator` (não só `Contributor`) para criar os `azurerm_role_assignment` dos exemplos; conceder via `scripts/sp-grant-user-access-administrator --client-id <id>`.
- Key Vault `waspfoundation*` usa access policy (RBAC desabilitado) → dar acesso a identidades via `azurerm_key_vault_access_policy`, não role assignment.
- `terraform destroy` emite warning benigno: CRDs do cert-manager são mantidos pela `resource-policy: keep` do chart no `helm uninstall`. Como o cluster inteiro é destruído junto, os CRDs somem com o control plane — nada fica órfão no Azure. O mesmo vale para os CRDs do Istio.
- O ingress-istio serve certificado **Let's Encrypt STAGING** (issuer `(STAGING) …`) → `curl` HTTPS falha na verificação da CA. Testar endpoints com `curl -k`; não é bug. O warning `discarding CNAME record` no external-dns quando há A+CNAME no mesmo host também é benigno.
- Roteamento externo do ArgoCD no exemplo istio vem do chart `istio-gateway` (Gateway `public-ingress-argocd` + VirtualService no namespace `istio-ingress`), NÃO do `argo-cd-config` (que só tem subcharts `ingress-azure`/`ingress-nginx`, ambos ociosos no istio). Não procurar VS/Gateway do argocd no namespace `argocd`.
- **PENDENTE (achado 2026-08-22):** o redirect HTTP→HTTPS **nunca dispara** nos VirtualServices do `istio-gateway`. O match `scheme: {exact: http}` não casa via Gateway na porta 80 (o Envoy não popula `:scheme` nesse caminho), então `argocd`/`httpbin`/`gateway` servem HTTP puro com 200 em vez de 302. Correção: trocar o match por `port: 80` em `src/helm/charts/istio-gateway/templates/virtualservice.yaml` e no VS do httpbin. **Não** usar `httpsRedirect: true` no Gateway — foi evitado de propósito para não conflitar com a renovação ACME HTTP01.
- SSO azuread do ArgoCD: o clientSecret é gravado no Key Vault por `argocd_app_registration_password` e injetado em `argocd-secret` via ExternalSecret `argocd-secret-merge-oidc-azuread` (`creationPolicy: Merge`). Validar com `GET /api/v1/settings` → `oidcConfig.name=AzureAD`.
- App-of-apps aponta para o repo externo `git@github.com:smsilva/wasp-gitops.git` (branch `dev`, path `infrastructure/charts/applications`) via SSH. A chave é `secret/argocd-repo-creds-ssh-private-key-base64-encoded` no Key Vault (base64 SEM quebras: `base64 -w0`), injetada por ExternalSecret `argocd-repo-creds-github`. Ao trocar a chave SSH local, atualizar esse secret no AKV senão o sync do app-of-apps falha na auth do GitHub.

## external-secrets (ESO 2.9.0)

- Autentica no Key Vault via **Workload Identity** (sem client_secret no cluster): anota o SA `external-secrets` com `azure.workload.identity/client-id` e usa `authType: WorkloadIdentity` + `serviceAccountRef` no `ClusterSecretStore`.
- ESO 2.9.0 serve o CRD apenas em `external-secrets.io/v1` (v1beta1 E v1alpha1 `served=false`, `unsafeServeV1Beta1: false`); usar `apiVersion: external-secrets.io/v1` em TODOS os `ExternalSecret` (schema idêntico entre versões). Manifests em versões antigas falham no apply com `ExternalSecret "" not found`. Já corrigido em `src/helm/modules/argo-cd/templates/extra-objects.yaml` (era v1beta1) e no repo externo `wasp-gitops` (`infrastructure/charts/nri-bundle-foundation`, era v1alpha1).
- `src/active-directory/workload-identity` é o módulo reutilizável (user-assigned MI + federated credential); requer o output `oidc_issuer_url` de `src/cluster`.

## external-dns (Workload Identity)

- O provider azure do external-dns escolhe o modo de auth pela flag no `azure.json` (secret `azure-config-file` do chart `external-dns-config`): `useWorkloadIdentityExtension: true` (MI federada) vs `useManagedIdentityExtension: true` (kubelet SP). Não passar `aadClientId/aadClientSecret` no modo Workload Identity — o client-id vem da anotação do SA.
- MI federada do external-dns precisa de `DNS Zone Contributor` na DNS Zone (não no RG). O antigo `azurerm_role_assignment.kubelet_contributor_on_dns_zone` foi **removido** (2026-08-22): `identity_client_id` é obrigatório no módulo e o chart `external-dns-config` fixa `useWorkloadIdentityExtension: true`, então o modo kubelet não existe mais em nenhum exemplo. Não reintroduzir — a kubelet identity é alcançável via IMDS por qualquer pod do nó, o que daria escrita na zona DNS a um workload comprometido.

Ver `HANDOFF.md` para o estado detalhado da migração e pendências.

## Estratégia de migração (acordada)

Migrar **um exemplo por vez**, começando por `cluster_argocd_ingress_istio`. Os demais exemplos permanecem em versões antigas (e podem ficar temporariamente quebrados quanto aos módulos compartilhados) até que o exemplo em foco seja **provisionado de verdade, validado e destruído**. Só então migrar os próximos.

## Convenções

- Rodar `terraform fmt` antes de commitar.
- Validar com `terraform init -backend=false && terraform validate` (não requer credenciais).
- `.terraform.lock.hcl` NÃO é versionado (ver `.gitignore`).
