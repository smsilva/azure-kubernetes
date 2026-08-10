# HANDOFF

## Why

Atualizar providers e charts do exemplo `examples/cluster_argocd_ingress_istio` (azurerm v5, azuread v3, helm v3, AKS 1.34.9). Migrar **um exemplo por vez**, religando cada `install_*` isoladamente, provisionando de verdade, validando no cluster e destruindo antes de seguir. Módulos em `src/` são compartilhados pelos 5 exemplos — editá-los quebra os que ainda estão em provider antigo (aceito temporariamente). Ver `CLAUDE.md` para o mapa de versões por exemplo e os gotchas.

## In Progress

**Ambiente ATIVO** — cluster `wasp-sandbox-vpd54` (RG `wasp-sandbox-vpd54`) provisionado em 2026-08-10 (`terraform apply`, 35 recursos). Toggles em `install_cert_manager`, `install_external_secrets`, `install_external_dns`, `install_ingress_istio`, `install_httpbin`, `install_argocd` = `true`; `install_app_of_apps_infra` = `false`.

argocd validado end-to-end (ver `docs/migration-progress.md`): chart 10.3.2, 7 pods `Running`, **UI HTTP 200** em `https://argocd.vpd54.sandbox.wasp.silvios.me/` (curl `-k`: cert LE **STAGING**), **SSO azuread ativo** (`/api/v1/settings` → `oidcConfig.name=AzureAD`; clientSecret merged via ExternalSecret). Roteamento vem do chart `istio-gateway` (Gateway `public-ingress-argocd` + VS em `istio-ingress`), não do `argo-cd-config`.

**Fix aplicado:** `extra-objects.yaml` do módulo argo-cd migrado de `external-secrets.io/v1beta1` → `v1` (ESO 2.9.0 não serve v1beta1).

Próximo passo pretendido: religar `install_app_of_apps_infra = true` e validar as Applications sincronizando no ArgoCD. **Ambiente ainda não destruído** — destruir só após validar app-of-apps.

## Open Questions / Hypotheses

- ArgoCD (chart 10.3.2, bump 7→10): revisar mudanças de configmap/RBAC/CRDs e o SSO via azuread (`instance.client_id`) ao religar. Pode exigir ajuste de `values`/templates.
- Charts com bump commitado mas NÃO validados: external-dns 1.21.1, ingress-nginx 4.15.1 (só usados por outros exemplos, ainda não migrados).
- Charts locais que mudam só conteúdo de template (mesmos `set`/`values`) → helm provider não detecta diff. Numa reprovisão do zero não é problema (recria tudo); só forçar `-replace='module.<mod>[0].helm_release.<release>'` se reinstalar num cluster já existente.

## Known Broken

- **Outros 4 exemplos** (`cluster_argocd_ingress_azure`, `_nginx`, `cluster_one_nodepool`, `cluster_two_nodepools`) — *intencional*: módulos compartilhados já em azurerm v5/helm v3 quebram esses exemplos até migrá-los. `two_nodepools` usa `src/nodepool` (já v4+). Ajustes por exemplo: subir provider p/ v5, adicionar `node_provisioning_profile`, `application_id`→`client_id`, pin helm v3.
- **`azurerm_role_assignment.kubelet_contributor_on_dns_zone`** (em `examples/common/variables.tf`, compartilhado, sem `count`) — *intencional*: mantido intacto para não quebrar outros exemplos; fica ocioso no istio (external-dns usa MI federada). Remover só ao migrar os demais.
- **Chart `ingress-azure` removido** — *inesperado*: `helm fetch` não retornou o chart e o diretório foi apagado. Usado só pelo exemplo azure. Ao migrar, refazer fetch de `oci://mcr.microsoft.com/azure-application-gateway/charts/ingress-azure` ou remover em definitivo.

## How to Resume

Ambiente `vpd54` já ativo (não reprovisionar — apply gera novo id e recria tudo). Para religar app-of-apps sobre o cluster existente:

```bash
cd examples/cluster_argocd_ingress_istio
# editar main.tf: install_app_of_apps_infra = true
terraform init
terraform plan -out=/tmp/aoa.tfplan   # NÃO usar apply -auto-approve: classifier exige plan visível
terraform apply /tmp/aoa.tfplan
# se helm não detectar diff em chart local (mesmos set/values):
#   terraform apply -replace='module.app_of_apps_infra[0].helm_release.<release>'
az aks get-credentials --resource-group wasp-sandbox-vpd54 --name wasp-sandbox-vpd54 --admin --overwrite-existing
kubectl get applications -n argocd   # validar Applications Synced/Healthy
# UI: https://argocd.vpd54.sandbox.wasp.silvios.me (curl -k: cert LE staging)
```

## Next Steps

1. ✅ external-dns via Workload Identity validado no cluster (auth + leitura da zona; ver `docs/migration-progress.md`).
2. ✅ ingress-istio religado (Istio 1.30.3); Gateway + 3 certificados cert-manager (`READY=True`) e external-dns **escrevendo** na zona (A record `gateway.vtl26` + CNAMEs/TXT). Ver `docs/migration-progress.md`.
3. ✅ httpbin religado; HTTP 200 end-to-end via Gateway (cert LE staging, curl `-k`; mTLS SPIFFE ok). Ver `docs/migration-progress.md`.
4. ✅ argocd religado (chart 10.3.2); UI HTTP 200 + SSO azuread validados. Fix: ExternalSecret v1beta1→v1. Ver `docs/migration-progress.md`.
5. Religar app-of-apps-infra; validar Applications sincronizando. Ambiente `vpd54` ainda ativo.
6. Provisionar a stack completa, validar end-to-end e **destruir**.
7. Só então migrar os outros 4 exemplos (ver Known Broken).

> Before trusting anything time-sensitive above, run `git status`, `git diff`, and `git log` against the base branch.
