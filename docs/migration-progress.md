# Migration progress log

Histórico de passos concluídos da migração de `examples/cluster_argocd_ingress_istio`
(azurerm v5 / azuread v3 / helm v3 / AKS 1.34.9). Ver `HANDOFF.md` para o estado atual
e os próximos passos.

## 2026-08-10 — argocd religado; UI + SSO azuread validados

- `install_argocd = true`. Cluster `wasp-sandbox-vpd54` provisionado do zero
  (`terraform apply`, **35 recursos**, 0 erros). Chart argo-cd **10.3.2** (bump 7→10)
  subiu com `atomic=true` — os 7 pods `Running 1/1`, sem restarts
  (`application-controller`, `applicationset-controller`, `dex-server`,
  `notifications-controller`, `redis`, `repo-server`, `server`).
- **Fix necessário antes do apply:** os 5 `ExternalSecret` em
  `src/helm/modules/argo-cd/templates/extra-objects.yaml` usavam
  `external-secrets.io/v1beta1`, que o ESO 2.9.0 não serve (`unsafeServeV1Beta1: false`).
  Migrados para `external-secrets.io/v1` (schema idêntico: `spec.data`/`secretKey`/
  `remoteRef`/`target`/`secretStoreRef`). Todos os 5 `SecretSynced`/`READY=True`.
- **SSO azuread end-to-end:** `argocd_app_registration` criou a app azuread; o clientSecret
  foi gravado no Key Vault e o ExternalSecret `argocd-secret-merge-oidc-azuread` fez o
  **merge** em `argocd-secret` (`oidc.azuread.clientSecret` presente). `argocd-cm.oidc.config`
  com `name: AzureAD` + `clientID` da app + issuer do tenant. A API
  `/api/v1/settings` retorna `oidcConfig.name=AzureAD` → login SSO servido pelo argocd-server.
- **Roteamento istio:** o chart `argo-cd-config` só tem subcharts `ingress-azure`/
  `ingress-nginx` (ambos `enabled: false` no exemplo istio → corretamente ocioso). O
  roteamento externo vem do chart `istio-gateway` (parte do ingress-istio): Gateway
  `public-ingress-argocd` + VirtualService `argocd-virtual-service-public`
  (host `argocd.vpd54.sandbox.wasp.silvios.me` → `argocd-server.argocd.svc:80`), ambos no
  namespace `istio-ingress`.
- **HTTP 200 end-to-end** por `https://argocd.vpd54.sandbox.wasp.silvios.me/`:
  `<title>Argo CD</title>`. Cert servido é **Let's Encrypt STAGING**
  (`(STAGING) Ersatz Emmer YR2`) → curl exige `-k`. Cert `ingress-argocd` `READY=True`,
  A record `argocd.vpd54` escrito pelo external-dns (`Succeeded`).

## 2026-08-10 — httpbin religado; HTTP 200 end-to-end via Gateway

- `install_httpbin = true` no cluster `wasp-sandbox-vtl26` (`terraform apply`, 2 recursos:
  `helm_release.httpbin` + `kubernetes_namespace_v1.httpbin`).
- Pod httpbin rodando; VirtualServices `mesh` + `public` criados
  (host `httpbin.vtl26.sandbox.wasp.silvios.me`); cert `ingress-httpbin` `READY=True`.
- **HTTP 200 end-to-end** por `https://httpbin.vtl26.sandbox.wasp.silvios.me/get`:
  - cert servido é **Let's Encrypt STAGING** (`(STAGING) Dastardly Durum YR1`) → curl exige
    `-k` (CA staging não confiável publicamente; esperado, não é bug).
  - response confirma cadeia completa: Envoy (`X-W1-Gateway: public-ingress-httpbin`),
    mTLS SPIFFE ingress→pod (`X-Forwarded-Client-Cert` com
    `spiffe://cluster.local/ns/httpbin/sa/httpbin`), DNS CNAME→A→LB `48.211.204.180`.

## 2026-08-10 — ingress-istio religado; escrita de DNS + certificados validados

- `install_ingress_istio = true`. Charts Istio revisados: subcharts upstream vendorados
  (`base`/`istiod`/`gateway`) já em **1.30.3**, versão mais recente do repo Istio — nada a
  bumpar no wrapper `src/helm/modules/ingress-istio`.
- Cluster `wasp-sandbox-vtl26` provisionado (`terraform apply`, 27 recursos). Istio subiu:
  `istio-base`, `istio-discovery`, `istio-gateway` + namespace `istio-ingress`.
- LoadBalancer `istio-ingress` com EXTERNAL-IP público `48.211.204.180`.
- **cert-manager emitiu os 3 certificados** (`ingress-gateway`, `ingress-argocd`,
  `ingress-httpbin`) → todos `READY=True`. 3 Gateways Istio criados.
- **external-dns escreveu na zona** (antes só leitura estava provada): via Workload Identity,
  criou o registro A `gateway.vtl26 → 48.211.204.180` (log `Updating A record...` +
  `az network dns record-set a list` → `ProvisioningState: Succeeded`), CNAMEs
  `argocd.vtl26`/`httpbin.vtl26` e TXT de ownership. Cadeia SA anotado → token federado →
  Azure DNS write **validada end-to-end**.

## 2026-08-10 — external-dns via Workload Identity validado no cluster

- Cluster `wasp-sandbox-02mzu` provisionado (`terraform apply`, 23 recursos). Toggles
  ativos: `install_cert_manager`, `install_external_secrets`, `install_external_dns`.
- external-dns autenticou via **Workload Identity** (confirmado nos logs):
  `Using workload identity extension to retrieve access token for Azure API.`
  seguido de `All records are already up to date` a cada ciclo de 1min, sem erro de
  credencial.
- SA `external-dns/external-dns` anotado com `azure.workload.identity/client-id`
  (`0e6fc972-0a44-436f-b678-b274bd3661f9`); pod com label `azure.workload.identity/use=true`.
- Role `DNS Zone Contributor` da MI federada na DNS Zone `sandbox.wasp.silvios.me`
  funcionando — external-dns lê a zona sem `AuthorizationFailed`.
- Sem registros a criar ainda (ingress-istio desligado, nenhum service/ingress com
  hostname). O ciclo de reconciliação sem erro já prova a cadeia
  SA anotado → token federado → API do Azure DNS.
