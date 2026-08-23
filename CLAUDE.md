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
- **Nunca** usar `-replace` em `module.ingress_istio[0].helm_release.istio_gateway` num cluster em uso: o replace é destroy+create (`helm uninstall`+`install`), recria o Service LoadBalancer, muda o IP público e derruba os três hosts até o external-dns reescrever o A record. Para validar mudança de template no chart, aplicar o objeto renderizado por `helm template` via `kubectl` com `app.kubernetes.io/managed-by: Helm` + annotations `meta.helm.sh/release-{name,namespace}` (assim um upgrade futuro o adota sem erro de ownership).
- Os templates autorais do chart `istio-gateway` (`gateway.yaml`, `virtualservice.yaml`, `certificate.yaml`) **não** são sobrescritos por `scripts/update-local-helm-charts-istio` — o script só troca os `.tgz` dos subcharts. Editar à vontade.
- Tudo que fica sob a chave `gateway:` no `values.yaml` do chart `istio-gateway` é repassado ao subchart `istio/gateway`, cujo `values.schema.json` **rejeita propriedades desconhecidas**. Valores próprios do repo precisam de uma chave de topo (ex.: `gatewayVirtualService`).
- Para provar que o external-dns tem permissão de **escrita** (os logs só dizem `All records are already up to date`, o que prova leitura): criar um `Service` `ExternalName` com a annotation `external-dns.alpha.kubernetes.io/hostname` num host descartável, conferir o CNAME + TXT de ownership na zona e deletar o Service.
- Acesso kubectl sem `kubelogin`: usar admin config → `az aks get-credentials --resource-group <rg> --name <cluster> --admin --overwrite-existing`.
- O SP do Terraform precisa de `User Access Administrator` (não só `Contributor`) para criar os `azurerm_role_assignment` dos exemplos; conceder via `scripts/sp-grant-user-access-administrator --client-id <id>`.
- Key Vault `waspfoundation*` usa access policy (RBAC desabilitado) → dar acesso a identidades via `azurerm_key_vault_access_policy`, não role assignment.
- `terraform destroy` emite warning benigno: CRDs do cert-manager são mantidos pela `resource-policy: keep` do chart no `helm uninstall`. Como o cluster inteiro é destruído junto, os CRDs somem com o control plane — nada fica órfão no Azure. O mesmo vale para os CRDs do Istio.
- O ingress-istio serve certificado **Let's Encrypt STAGING** (issuer `(STAGING) …`) → `curl` HTTPS falha na verificação da CA. Testar endpoints com `curl -k`; não é bug. O warning `discarding CNAME record` no external-dns quando há A+CNAME no mesmo host também é benigno.
- Roteamento externo do ArgoCD no exemplo istio vem do chart `istio-gateway` (Gateway `public-ingress-argocd` + VirtualService no namespace `istio-ingress`), NÃO do `argo-cd-config` (que só tem subcharts `ingress-azure`/`ingress-nginx`, ambos ociosos no istio). Não procurar VS/Gateway do argocd no namespace `argocd`.
- **RESOLVIDO (2026-08-23):** cert-manager do issuer `istio` migrou de HTTP01 para `dns01.azureDNS` (Workload Identity federada, `DNS Zone Contributor` na DNS Zone — mesmo padrão do `external-dns`). `istio-gateway` agora emite um único `Certificate` wildcard (`ingress-wildcard`, `*.<cname>.<domain>`) e cada `Gateway` usa `tls.httpsRedirect: true` no listener HTTP; as VirtualServices (`istio-gateway` e `httpbin`) não têm mais o `match`/`redirect` manual. Issuers `azure`/`nginx` continuam em HTTP01 — não migrados, fora de escopo. Gotcha: o certificado é wildcard, mas o **roteamento SNI do Gateway não é** — cada `Gateway` só aceita SNI para os hosts explicitamente listados em `hosts:`; um host novo não cadastrado em nenhum Gateway falha o handshake TLS mesmo coberto pelo wildcard (comportamento normal do Istio, não bug).
- SSO azuread do ArgoCD: o clientSecret é gravado no Key Vault por `argocd_app_registration_password` e injetado em `argocd-secret` via ExternalSecret `argocd-secret-merge-oidc-azuread` (`creationPolicy: Merge`). Validar com `GET /api/v1/settings` → `oidcConfig.name=AzureAD`.
- App-of-apps aponta para o repo externo `git@github.com:smsilva/wasp-gitops.git` (branch `dev`, path `infrastructure/charts/applications`) via SSH. A chave é `secret/argocd-repo-creds-ssh-private-key-base64-encoded` no Key Vault (base64 SEM quebras: `base64 -w0`), injetada por ExternalSecret `argocd-repo-creds-github`. Ao trocar a chave SSH local, atualizar esse secret no AKV senão o sync do app-of-apps falha na auth do GitHub.
- **RESOLVIDO (2026-08-23):** providers `kubernetes`/`helm` do exemplo istio trocados de `kube_admin_config` (credencial admin local, bypassa Azure RBAC e grava token em texto claro no state) para `kube_config` + `exec`/`kubelogin --login azurecli`. Membership no grupo `admin_group_object_ids` do cluster (com `azure_rbac_enabled = true`) já concede acesso equivalente a cluster-admin via Azure RBAC — não precisa de role assignment `Azure Kubernetes Service RBAC Cluster Admin` dedicada. Usar `--login azurecli` (não `spn`): `spn` exige `ARM_CLIENT_SECRET`, ausente no workflow de CI que usa OIDC federado (`ARM_USE_OIDC=true`); `azurecli` reaproveita a sessão já autenticada (local: `az login` do usuário; CI: `azure/login@v2`) sem `if` de ambiente. `server-id` do exec plugin é o app ID fixo do AKS AAD Server: `6dae42f8-4368-4678-94ff-3960e28e3630`. Gotcha: `kube_admin_config`/senha continuam aparecendo no `terraform state` mesmo assim — é atributo do recurso `azurerm_kubernetes_cluster` (exposto sempre que `disable_local_accounts != true`), a troca só elimina o *uso* pelos providers, não a presença no state.

## external-secrets (ESO 2.9.0)

- Autentica no Key Vault via **Workload Identity** (sem client_secret no cluster): anota o SA `external-secrets` com `azure.workload.identity/client-id` e usa `authType: WorkloadIdentity` + `serviceAccountRef` no `ClusterSecretStore`.
- ESO 2.9.0 serve o CRD apenas em `external-secrets.io/v1` (v1beta1 E v1alpha1 `served=false`, `unsafeServeV1Beta1: false`); usar `apiVersion: external-secrets.io/v1` em TODOS os `ExternalSecret` (schema idêntico entre versões). Manifests em versões antigas falham no apply com `ExternalSecret "" not found`. Já corrigido em `src/helm/modules/argo-cd/templates/extra-objects.yaml` (era v1beta1) e no repo externo `wasp-gitops` (`infrastructure/charts/nri-bundle-foundation`, era v1alpha1).
- `src/active-directory/workload-identity` é o módulo reutilizável (user-assigned MI + federated credential); requer o output `oidc_issuer_url` de `src/cluster`.

## external-dns (Workload Identity)

- O provider azure do external-dns escolhe o modo de auth pela flag no `azure.json` (secret `azure-config-file` do chart `external-dns-config`): `useWorkloadIdentityExtension: true` (MI federada) vs `useManagedIdentityExtension: true` (kubelet SP). Não passar `aadClientId/aadClientSecret` no modo Workload Identity — o client-id vem da anotação do SA.
- MI federada do external-dns precisa de `DNS Zone Contributor` na DNS Zone (não no RG). O antigo `azurerm_role_assignment.kubelet_contributor_on_dns_zone` foi **removido** (2026-08-22): `identity_client_id` é obrigatório no módulo e o chart `external-dns-config` fixa `useWorkloadIdentityExtension: true`, então o modo kubelet não existe mais em nenhum exemplo. Não reintroduzir — a kubelet identity é alcançável via IMDS por qualquer pod do nó, o que daria escrita na zona DNS a um workload comprometido.
- Consequência da mudança acima: `cluster_argocd_ingress_azure` e `cluster_argocd_ingress_nginx` falham em `terraform validate` (`identity_client_id` required, mas esses exemplos ainda passam `client_id`/`client_secret` pré-Workload-Identity para `external_secrets`/`external_dns`). É esperado — fazem parte dos "4 exemplos legado" ainda não migrados, não uma regressão nova.

Ver `HANDOFF.md` para o estado detalhado da migração e pendências.

## CI: acesso SSH a módulos privados (git::ssh)

- `network.tf`/`secrets.tf` puxam `vnet` e `argocd_app_registration_password` via `git::ssh://git@github.com/smsilva/{azure-network,azure-key-vault}.git` — repos privados. Um runner GitHub Actions não tem acesso por padrão.
- GitHub **rejeita** a mesma chave pública como deploy key em mais de um repositório (`422 key is already in use`). Solução: uma chave por repo módulo (`scripts/github-actions-configure-ssh-deploy-key`), mapeada por alias de host em `~/.ssh/config` + `git config url."ssh://git@github.com-<repo>/...".insteadOf "ssh://git@github.com/..."`.
- O `insteadOf` precisa casar a URL **exata** que o `git` recebe. O detector de módulo git do Terraform gera `ssh://git@github.com/owner/repo` (forma URL completa), não a forma SCP-like `git@github.com:owner/repo` — usar a forma errada faz o `insteadOf` nunca casar, silenciosamente (o clone cai de volta na identidade default).
- `local.arm_client_secret`/`module "variables"` (`src/variables`) só são usados por `cluster_argocd_ingress_azure` e `cluster_argocd_ingress_nginx` — vivem em arquivos próprios desses dois exemplos, não em `examples/common/variables.tf` (istio não paga o custo do `data "external"` a cada plan).

## Estratégia de migração (acordada)

Migrar **um exemplo por vez**, começando por `cluster_argocd_ingress_istio`. Os demais exemplos permanecem em versões antigas (e podem ficar temporariamente quebrados quanto aos módulos compartilhados) até que o exemplo em foco seja **provisionado de verdade, validado e destruído**. Só então migrar os próximos.

## Convenções

- Rodar `terraform fmt` antes de commitar. Cuidado: `terraform fmt -recursive examples` segue os symlinks de `examples/common/` e normaliza o arquivo inteiro — conferir com `git diff -w` antes de commitar junto de mudança funcional.
- Renderizar templates com a função nativa `templatefile()` dentro de um `locals`. **Não** reintroduzir `data "template_file"`: o provider `hashicorp/template` foi arquivado e não tem build `darwin_arm64`, o que impede `terraform init` em Apple Silicon.
- Validar com `terraform init -backend=false && terraform validate` (não requer credenciais).
- `.terraform.lock.hcl` NÃO é versionado (ver `.gitignore`).
- Charts locais sob `src/helm/charts/*`: não bumpar `Chart.yaml version` por edição só de template (sem mudança de subchart/`appVersion`) — precedente do histórico do repo (ex.: commit `ab80bbc`).
