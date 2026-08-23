# Migration progress log

History of completed steps in the migration of
`examples/cluster_argocd_ingress_istio` (azurerm v5 / azuread v3 / helm v3 /
AKS 1.34.9). See `HANDOFF.md` for the current state and next steps.

## 2026-08-10 — argocd re-enabled; UI + azuread SSO validated

- `install_argocd = true`. Cluster `wasp-sandbox-vpd54` provisioned from scratch
  (`terraform apply`, **35 resources**, 0 errors). The argo-cd chart **10.3.2**
  (bump 7→10) came up with `atomic=true` — all 7 pods `Running 1/1`, no restarts
  (`application-controller`, `applicationset-controller`, `dex-server`,
  `notifications-controller`, `redis`, `repo-server`, `server`).
- **Fix required before the apply:** the 5 `ExternalSecret`s in
  `src/helm/modules/argo-cd/templates/extra-objects.yaml` used
  `external-secrets.io/v1beta1`, which ESO 2.9.0 does not serve
  (`unsafeServeV1Beta1: false`). Migrated to `external-secrets.io/v1` (identical
  schema: `spec.data`/`secretKey`/`remoteRef`/`target`/`secretStoreRef`). All 5
  are `SecretSynced`/`READY=True`.
- **azuread SSO end-to-end:** `argocd_app_registration` created the azuread app;
  the clientSecret was written to the Key Vault and the
  `argocd-secret-merge-oidc-azuread` ExternalSecret **merged** it into
  `argocd-secret` (`oidc.azuread.clientSecret` present). `argocd-cm.oidc.config`
  carries `name: AzureAD` + the app's `clientID` + the tenant issuer. The
  `/api/v1/settings` API returns `oidcConfig.name=AzureAD` → SSO login served by
  argocd-server.
- **istio routing:** the `argo-cd-config` chart only has the
  `ingress-azure`/`ingress-nginx` subcharts (both `enabled: false` in the istio
  example → correctly idle). External routing comes from the `istio-gateway`
  chart (part of ingress-istio): Gateway `public-ingress-argocd` +
  VirtualService `argocd-virtual-service-public` (host
  `argocd.vpd54.sandbox.wasp.silvios.me` → `argocd-server.argocd.svc:80`), both
  in the `istio-ingress` namespace.
- **HTTP 200 end-to-end** on `https://argocd.vpd54.sandbox.wasp.silvios.me/`:
  `<title>Argo CD</title>`. The served certificate is **Let's Encrypt STAGING**
  (`(STAGING) Ersatz Emmer YR2`) → curl requires `-k`. Certificate
  `ingress-argocd` `READY=True`, A record `argocd.vpd54` written by external-dns
  (`Succeeded`).

## 2026-08-10 — httpbin re-enabled; HTTP 200 end-to-end through the Gateway

- `install_httpbin = true` on cluster `wasp-sandbox-vtl26` (`terraform apply`, 2
  resources: `helm_release.httpbin` + `kubernetes_namespace_v1.httpbin`).
- httpbin pod running; `mesh` + `public` VirtualServices created (host
  `httpbin.vtl26.sandbox.wasp.silvios.me`); certificate `ingress-httpbin`
  `READY=True`.
- **HTTP 200 end-to-end** on `https://httpbin.vtl26.sandbox.wasp.silvios.me/get`:
  - the served certificate is **Let's Encrypt STAGING** (`(STAGING) Dastardly
    Durum YR1`) → curl requires `-k` (the staging CA is not publicly trusted;
    expected, not a bug).
  - the response confirms the full chain: Envoy
    (`X-W1-Gateway: public-ingress-httpbin`), SPIFFE mTLS ingress→pod
    (`X-Forwarded-Client-Cert` with
    `spiffe://cluster.local/ns/httpbin/sa/httpbin`), DNS CNAME→A→LB
    `48.211.204.180`.

## 2026-08-10 — ingress-istio re-enabled; DNS writes + certificates validated

- `install_ingress_istio = true`. Istio charts reviewed: the vendored upstream
  subcharts (`base`/`istiod`/`gateway`) are already at **1.30.3**, the latest
  version in the Istio repo — nothing to bump in the
  `src/helm/modules/ingress-istio` wrapper.
- Cluster `wasp-sandbox-vtl26` provisioned (`terraform apply`, 27 resources).
  Istio came up: `istio-base`, `istio-discovery`, `istio-gateway` + the
  `istio-ingress` namespace.
- LoadBalancer `istio-ingress` with public EXTERNAL-IP `48.211.204.180`.
- **cert-manager issued all 3 certificates** (`ingress-gateway`,
  `ingress-argocd`, `ingress-httpbin`) → all `READY=True`. 3 Istio Gateways
  created.
- **external-dns wrote to the zone** (only reads had been proven before): through
  Workload Identity it created the A record `gateway.vtl26 → 48.211.204.180`
  (log `Updating A record...` + `az network dns record-set a list` →
  `ProvisioningState: Succeeded`), the `argocd.vtl26`/`httpbin.vtl26` CNAMEs, and
  the ownership TXT. The chain annotated SA → federated token → Azure DNS write is
  **validated end-to-end**.

## 2026-08-10 — external-dns via Workload Identity validated on the cluster

- Cluster `wasp-sandbox-02mzu` provisioned (`terraform apply`, 23 resources).
  Active toggles: `install_cert_manager`, `install_external_secrets`,
  `install_external_dns`.
- external-dns authenticated through **Workload Identity** (confirmed in the
  logs): `Using workload identity extension to retrieve access token for Azure
  API.` followed by `All records are already up to date` on every 1-minute cycle,
  with no credential error.
- SA `external-dns/external-dns` annotated with
  `azure.workload.identity/client-id`
  (`0e6fc972-0a44-436f-b678-b274bd3661f9`); pod labeled
  `azure.workload.identity/use=true`.
- The federated MI's `DNS Zone Contributor` role on the DNS Zone
  `sandbox.wasp.silvios.me` works — external-dns reads the zone without
  `AuthorizationFailed`.
- No records to create yet (ingress-istio disabled, no service/ingress with a
  hostname). An error-free reconciliation cycle already proves the chain
  annotated SA → federated token → Azure DNS API.
