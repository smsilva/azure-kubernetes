# HANDOFF — Atualização de providers e charts

Estado da migração incremental, começando por `examples/cluster_argocd_ingress_istio`.
Estratégia: migrar **um exemplo por vez**; provisionar de verdade, validar e destruir antes de migrar o próximo. Ver `CLAUDE.md` para o mapa de versões por exemplo.

Última atualização: 2026-08-10

---

## Etapa atual: `cluster_argocd_ingress_istio`

### Objetivo imediato
Subir **apenas o cluster AKS 1.34.9** (todos os `install_*` em `false` no `main.tf`) na conta pessoal, com providers atualizados. `plan`/`apply` a cargo do usuário (backend local).

### ✅ Feito

**Providers (`examples/cluster_argocd_ingress_istio/provider.tf`)**
- `azurerm`: `>= 3.0.0, < 4.0.0` → `>= 5.0.0, < 6.0.0`
- `azuread`: `>= 2.22.0, < 3.0.0` → `>= 3.0.0, < 4.0.0`
- `helm`: adicionado pin `>= 3.0.0, < 4.0.0` (antes sem pin → puxava a última e quebrava)
- `provider "azurerm"`: adicionado `resource_provider_registrations = "legacy"` (v5 mudou o default para `none`)
- `provider "helm"`: bloco `kubernetes { ... }` → atributo `kubernetes = { ... }` (sintaxe helm v3)

**Módulo `src/cluster/main.tf` (COMPARTILHADO)**
- Adicionado bloco `node_provisioning_profile { mode = "Manual" }` — obrigatório no azurerm v5.

**Módulo `src/nodepool/main.tf` (COMPARTILHADO)**
- `enable_auto_scaling` → `auto_scaling_enabled`
- `enable_node_public_ip` → `node_public_ip_enabled`
- `enable_host_encryption` → `host_encryption_enabled`
  (renomeações do azurerm v4)

**azuread v3 — atributo `application_id` removido → `client_id`**
- `examples/cluster_argocd_ingress_istio/main.tf:119` (`sso_application_id`)
- `examples/common/secrets.tf:9` (symlink compartilhado — afeta os 3 exemplos argocd)

**Módulos helm migrados para sintaxe v3 (`set = [...]`)**
- `src/helm/modules/external-dns/main.tf`
- `src/helm/modules/httpbin/main.tf`
- `src/helm/modules/ingress-istio/main.tf`
  (cert-manager, external-secrets, ingress-azure, app-of-apps-infra já tinham sido migrados no commit `64971b1`)

**Validação**
- `terraform init -backend=false && terraform validate` → **Success** (com warnings, ver abaixo).
- Providers resolvidos: azurerm 5.0.1, azuread 3.9.0, helm 3.2.0, kubernetes 3.2.1.

### ⚠️ Efeito colateral — charts locais atualizados
`./scripts/update-local-helm-charts` foi executado na investigação e **substituiu charts locais** (o script faz `rm -rf` + `helm fetch` quando a versão difere). Mantido a pedido do usuário. Precisam ser **revisados/validados** junto com o provisionamento:

| Chart | Antes (HEAD) | Agora |
|---|---|---|
| argo-cd | 7.5.2 | 10.3.2 |
| cert-manager | v1.15.3 | v1.21.1 |
| external-dns | 1.15.0 | 1.21.1 |
| external-secrets | 0.10.3 | 2.9.0 |
| ingress-nginx | 4.11.2 | 4.15.1 |

- Bumps grandes (ex.: argo-cd 7→10, external-secrets 0.10→2.9) podem exigir ajustes nos `values`/templates dos módulos e nos CRDs. Validar ao religar cada `install_*`.

### ✅ Charts istio atualizados 1.22.2 → 1.30.3
Rodado `scripts/update-local-helm-charts-istio` pelo usuário. Subcharts substituídos:
- `istio-base/charts/base-1.22.2.tgz` → `base-1.30.3.tgz`
- `istio-discovery/charts/istiod-1.22.2.tgz` → `istiod-1.30.3.tgz`
- `istio-gateway/charts/gateway-1.22.2.tgz` → `gateway-1.30.3.tgz`

Verificação:
- `helm template` renderiza os 3 wrappers sem erros nem warnings.
- APIs usadas nos templates ainda servidas no CRD 1.30.3: `telemetry.istio.io/v1alpha1` (telemetry.yaml), `networking.istio.io/v1alpha3` (gateway.yaml, virtualservice.yaml).
- `appVersion` dos 3 wrapper `Chart.yaml` atualizado `1.18.2` → `1.30.3` (metadado; a `version:` do wrapper — 0.5.0/0.6.0/0.4.0 — foi mantida).

### ✅ Warnings de deprecação resolvidos
- `kubernetes_namespace` → `kubernetes_namespace_v1` (recurso + referências):
  - `src/helm/modules/httpbin/main.tf`
  - `src/helm/modules/ingress-istio/main.tf`
- `terraform validate` agora retorna `Success!` sem warnings.

### ✅ Cluster provisionado (apply real)
`terraform apply` executado na subscription `wasp-sandbox`. Resultado: cluster AKS 1.34.9 + VNet/subnets + 5 role assignments. Output `url_gateway = gateway.2g0nh.sandbox.wasp.silvios.me`.
- Confirma que a migração azurerm v5 (`node_provisioning_profile`, `auto_scaling_enabled`) funciona no recurso real.

### ⚠️ Permissão do Service Principal (resolvido)
O primeiro apply falhou com `403 AuthorizationFailed` nos 5 `azurerm_role_assignment` — o SP `terraform-wasp-sandbox` (`2ef8b61a...`) só tinha `Contributor`, faltava `Microsoft.Authorization/roleAssignments/write`.
- Corrigido concedendo **User Access Administrator @ subscription** via novo script `scripts/sp-grant-user-access-administrator`.
- Documentado no `README.md` (seção "Service Principal Permissions").
- Re-apply completou os 5 role assignments (5 added, 0 changed, 0 destroyed).

### Religando módulos um a um (apply + validar + commit)
- [x] **cert-manager** v1.21.1 — commit `8b1c9b5`. 3 pods Running, 6 CRDs, 7 ClusterIssuers READY.
- [x] **external-secrets** v0.10.3 → 2.9.0 — migrado para **Azure Workload Identity** (sem client_secret no cluster). ClusterSecretStore `store validated` (Valid) e ExternalSecret de teste `SecretSynced`. Novos recursos: `src/active-directory/workload-identity` (user-assigned MI + federated credential), `azurerm_key_vault_access_policy`. Notas da migração:
  - ESO 2.9.0 serve o CRD `ClusterSecretStore` apenas em `external-secrets.io/v1` (v1beta1 `served=false`) → config chart migrado para `v1`.
  - `podLabels.azure\.workload\.identity/use` precisa `type = "string"` no helm_release `set` (senão o helm envia boolean e o k8s rejeita o label).
  - Requer output novo `oidc_issuer_url` em `src/cluster/output.tf`.
  - `azurerm_federated_identity_credential` no azurerm v5 usa `user_assigned_identity_id` (não `parent_id`/`resource_group_name`).
- [ ] external-dns (chart 1.15.0 → 1.21.1)
- [ ] ingress-istio (charts istio 1.30.3 já commitados)
- [ ] argocd (chart 7.5.2 → 10.3.2 — bump grande) + httpbin
- [ ] app-of-apps-infra

Ao final: provisionar tudo, validar, **destruir**.

### Acesso ao cluster (kubectl)
`kubelogin` não está instalado → usar admin config:
`az aks get-credentials --resource-group wasp-sandbox-2g0nh --name wasp-sandbox-2g0nh --admin --overwrite-existing`

---

## Pendências dos outros exemplos (fazer DEPOIS do istio)

Os módulos compartilhados já foram alterados para azurerm v5 / helm v3. Isso **quebra** os exemplos ainda em versões antigas. Migrar cada um:

- [ ] `cluster_argocd_ingress_azure` (azurerm v4, helm v3) — precisa subir para v5 e ganhar `node_provisioning_profile`; ajustar `main.tf` `application_id`→`client_id` (linha ~114).
- [ ] `cluster_argocd_ingress_nginx` (azurerm v3, sem pin helm) — subir azurerm v3→v5, pin helm v3, migrar módulo ingress-nginx se necessário, `application_id`→`client_id` (linha ~103).
- [ ] `cluster_one_nodepool` (azurerm v3) — subir para v5.
- [ ] `cluster_two_nodepools` (azurerm v3) — subir para v5; **usa `src/nodepool`** (já migrado para v4+, então este exemplo está quebrado até subir o provider).

### Breaking changes de referência
- azurerm v4: renomeações de `enable_*`→`*_enabled` em AKS/nodepool; `subscription_id` obrigatório (via `ARM_SUBSCRIPTION_ID`, já setado no ambiente).
- azurerm v5: `node_provisioning_profile` obrigatório em `azurerm_kubernetes_cluster`; `resource_provider_registrations` default `none` (usar `"legacy"` para manter comportamento antigo).
- azuread v3: atributo `application_id` de `azuread_application` removido → `client_id`.
- helm v3: `set {}`/`registry {}`/`kubernetes {}` (blocos) → `set = [...]`/`registries = [...]`/`kubernetes = {...}` (atributos).
