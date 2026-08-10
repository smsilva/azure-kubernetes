# HANDOFF

## Why

Atualizar providers e charts do exemplo `examples/cluster_argocd_ingress_istio` (azurerm v5, azuread v3, helm v3, AKS 1.34.9). Migrar **um exemplo por vez**, religando cada `install_*` isoladamente, provisionando de verdade, validando no cluster e destruindo antes de seguir. Módulos em `src/` são compartilhados pelos 5 exemplos — editá-los quebra os que ainda estão em provider antigo (aceito temporariamente). Ver `CLAUDE.md` para o mapa de versões por exemplo e os gotchas.

## In Progress

**Ambiente destruído** — cluster `wasp-sandbox-vtl26` provisionado e destruído em 2026-08-10 (`terraform destroy`, 29 recursos; sem AKS/RG/A record `vtl26` remanescentes no Azure). Toggles seguem em `install_cert_manager`, `install_external_secrets`, `install_external_dns`, `install_ingress_istio`, `install_httpbin` = `true`; `install_argocd`, `install_app_of_apps_infra` = `false`.

ingress-istio + httpbin validados end-to-end antes do destroy (ver `docs/migration-progress.md`): Istio 1.30.3, LB público, cert-manager emitiu os certificados (`READY=True`), external-dns **escreveu** na zona via Workload Identity, e httpbin respondeu **HTTP 200** via Gateway (curl `-k`: cert Let's Encrypt **STAGING**). mTLS SPIFFE ingress→pod confirmado.

Próximo passo pretendido: reprovisionar (cada apply gera novo `random_string.id` → nomes mudam), religar `install_argocd = true` e validar UI/SSO do ArgoCD (chart 10.3.2) via azuread.

## Open Questions / Hypotheses

- Bump grande de charts Istio (1.22.2 → 1.30.3, já no repo): pode exigir ajuste de `values`/CRDs em `src/helm/modules/ingress-istio` ao religar.
- cert-manager precisa emitir o certificado do Gateway do Istio; `certificate_type`/`certificate_server` já cabeados no módulo — validar emissão real.
- Charts locais só mudam conteúdo de template (mesmos `set`/`values`) → helm provider não detecta diff. Ao religar ingress-istio talvez seja preciso `-replace='module.ingress_istio[0].helm_release.<release>'`.
- Charts com bump commitado mas NÃO validados: argo-cd 10.3.2, external-dns 1.21.1, ingress-nginx 4.15.1. Bumps grandes (argo-cd 7→10) podem exigir ajuste de `values`/templates/CRDs ao religar.
- ArgoCD (chart 10.3.2): revisar mudanças de configmap/RBAC/CRDs e o SSO via azuread (`instance.client_id`) ao religar.

## Known Broken

- **Outros 4 exemplos** (`cluster_argocd_ingress_azure`, `_nginx`, `cluster_one_nodepool`, `cluster_two_nodepools`) — *intencional*: módulos compartilhados já em azurerm v5/helm v3 quebram esses exemplos até migrá-los. `two_nodepools` usa `src/nodepool` (já v4+). Ajustes por exemplo: subir provider p/ v5, adicionar `node_provisioning_profile`, `application_id`→`client_id`, pin helm v3.
- **`azurerm_role_assignment.kubelet_contributor_on_dns_zone`** (em `examples/common/variables.tf`, compartilhado, sem `count`) — *intencional*: mantido intacto para não quebrar outros exemplos; fica ocioso no istio (external-dns usa MI federada). Remover só ao migrar os demais.
- **Chart `ingress-azure` removido** — *inesperado*: `helm fetch` não retornou o chart e o diretório foi apagado. Usado só pelo exemplo azure. Ao migrar, refazer fetch de `oci://mcr.microsoft.com/azure-application-gateway/charts/ingress-azure` ou remover em definitivo.

## How to Resume

```bash
cd examples/cluster_argocd_ingress_istio
# editar main.tf: install_ingress_istio = true
terraform init
terraform apply -auto-approve   # cria random_string.id novo → nome de cluster/RG muda a cada apply
az aks get-credentials --resource-group <rg> --name <cluster> --admin --overwrite-existing
az network dns record-set a list --resource-group wasp-foundation --zone-name sandbox.wasp.silvios.me -o table
kubectl -n external-dns logs deploy/external-dns --tail=30   # esperado: linha "CREATE" do registro
```

## Next Steps

1. ✅ external-dns via Workload Identity validado no cluster (auth + leitura da zona; ver `docs/migration-progress.md`).
2. ✅ ingress-istio religado (Istio 1.30.3); Gateway + 3 certificados cert-manager (`READY=True`) e external-dns **escrevendo** na zona (A record `gateway.vtl26` + CNAMEs/TXT). Ver `docs/migration-progress.md`.
3. ✅ httpbin religado; HTTP 200 end-to-end via Gateway (cert LE staging, curl `-k`; mTLS SPIFFE ok). Ver `docs/migration-progress.md`.
4. Religar argocd (chart 10.3.2); validar UI/SSO via azuread. Modelo sugerido: Opus (bump argo-cd 7→10 pode exigir ajuste de configmap/RBAC/CRDs + SSO `instance.client_id`).
5. Religar app-of-apps-infra; validar.
6. Provisionar a stack completa, validar end-to-end e **destruir**.
7. Só então migrar os outros 4 exemplos (ver Known Broken).

> Before trusting anything time-sensitive above, run `git status`, `git diff`, and `git log` against the base branch.
