# cert-manager HTTP01 → DNS01 Migration (issuer `istio`) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Migrate the ACME solver used by the `istio` cert-manager `ClusterIssuer`s from `http01` to `dns01.azureDNS` (Workload Identity auth), switch `examples/cluster_argocd_ingress_istio` to a single wildcard certificate, and let the Istio `Gateway` itself perform the HTTP→HTTPS redirect instead of the per-VirtualService `match`+`redirect` workaround.

**Architecture:** A new federated Workload Identity (same pattern as `external-dns`/`external-secrets`) grants the cert-manager controller `DNS Zone Contributor` on the existing Azure DNS zone. The `cert-manager-issuers` chart's `ClusterIssuer` template picks `http01` or `dns01` per issuer entry (only `istio` opts into `dns01`; `azure`/`nginx` are untouched). The `istio-gateway` chart drops its N per-host `Certificate` resources for one wildcard `Certificate`, sets `tls.httpsRedirect: true` on every Gateway's port-80 listener, and the VirtualServices (istio-gateway's own + httpbin's) drop their manual redirect `match` blocks, which existed only to keep `/.well-known/acme-challenge/` reachable over plain HTTP for HTTP01 — no longer needed once HTTP01 is gone.

**Tech Stack:** Terraform (`azurerm` >= 5.0, `helm` >= 3.0), Helm charts (local, vendored), cert-manager v1.21.1 (vendorized), Istio 1.30.3, Azure DNS.

**Spec:** `docs/superpowers/specs/2026-08-22-cert-manager-dns01-migration-design.md`

## Global Constraints

- Scope is `examples/cluster_argocd_ingress_istio` only. Do not touch `cluster_argocd_ingress_azure`, `cluster_argocd_ingress_nginx`, `cluster_one_nodepool`, `cluster_two_nodepools`.
- Only the `istio` issuer switches solver. The `azure` and `nginx` `ClusterIssuer` entries in `cert-manager-issuers` must keep rendering `http01` exactly as today — verify this with `helm template` after every chart change in this plan.
- No Service Principal client secret anywhere. Auth is Workload Identity federation only (mirrors `src/active-directory/workload-identity` as already used by `external-dns`/`external-secrets`).
- No external webhook (`cert-manager-webhook-azure-dns`). Use the vendorized cert-manager v1.21.1's native `dns01.azureDNS` solver.
- Do not flip `httpsRedirect: true` on the `Gateway` until the corresponding VirtualService's manual redirect `match` block is removed in the same task's commit — never ship both at once (double redirect is harmless but the spec's whole point is deleting the manual one).
- `terraform apply -auto-approve` and non-dry-run `helm upgrade` against the live cluster are blocked/gated for this session — use `terraform plan -out=<file>` then `terraform apply <file>`, and ask the user before any live `helm upgrade`.
- Validate Terraform changes with `terraform init -backend=false && terraform validate` (no credentials required); do not run this against `cluster_argocd_ingress_azure`/`_nginx` and treat their pre-existing `terraform validate` failures as out of scope (documented legacy state in `CLAUDE.md`).
- Run `terraform fmt` on touched `.tf` files before commit; if run with `-recursive` on `examples/`, diff with `git diff -w` before committing to avoid bundling unrelated symlink-wide reformatting.

---

### Task A: `cert-manager-issuers` chart — conditional DNS01 solver for the `istio` issuer

**Files:**
- Modify: `src/helm/charts/cert-manager-issuers/values.yaml`
- Modify: `src/helm/charts/cert-manager-issuers/templates/cluster-issuer.yaml`

**Interfaces:**
- Produces: chart values `azureDNS.subscriptionID`, `azureDNS.resourceGroupName`, `azureDNS.hostedZoneName`, `azureDNS.managedIdentity.clientID` (consumed by Task B's `helm_release.cert_manager_issuers` `set` blocks) and per-issuer `solver` field (`istio` entry gets `dns01`; `azure`/`nginx` entries are absent, defaulting to `http01`).

- [ ] **Step 1: Render the current chart and confirm baseline (all three issuers are `http01`)**

Run:
```bash
helm template cert-manager-issuers src/helm/charts/cert-manager-issuers --show-only templates/cluster-issuer.yaml | grep -c "http01:"
```
Expected: `6` (2 servers × 3 issuers, all still `http01` — this is the "red" baseline before the change).

- [ ] **Step 2: Add the `azureDNS` values block and the `solver` field on the `istio` issuer**

Edit `src/helm/charts/cert-manager-issuers/values.yaml` to:

```yaml
fqdn: gateway.environment-id.sandbox.wasp.silvios.me

letsencrypt:
  email: alerts@silvios.me

  servers:
    - name: production
      host: acme-v02

    - name: staging
      host: acme-staging-v02

  issuers:
    - name:  azure
      class: azure/application-gateway

    - name:  nginx
      class: nginx

    - name:  istio
      class: istio
      solver: dns01

azureDNS:
  subscriptionID: ""
  resourceGroupName: ""
  hostedZoneName: ""
  managedIdentity:
    clientID: ""
```

(Values default to empty strings; Task B's Terraform `set` blocks fill them in at deploy time. Empty strings are harmless for `helm template` rendering checks in this task.)

- [ ] **Step 3: Make the solver conditional in the `ClusterIssuer` template**

Edit `src/helm/charts/cert-manager-issuers/templates/cluster-issuer.yaml`, replacing the single `solvers:` block:

```yaml
{{- range $server :=  .Values.letsencrypt.servers }}
{{- range $issuer := $.Values.letsencrypt.issuers }}
---
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-{{ $server.name }}-{{ $issuer.name }}
spec:
  acme:
    email: {{ $.Values.letsencrypt.email }}
    server: https://{{ $server.host }}.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: letsencrypt-{{ $server.name }}-{{ $issuer.name }}-issuer-account-key
    solvers:
      {{- if eq (default "http01" $issuer.solver) "dns01" }}
      - dns01:
          azureDNS:
            subscriptionID: {{ $.Values.azureDNS.subscriptionID }}
            resourceGroupName: {{ $.Values.azureDNS.resourceGroupName }}
            hostedZoneName: {{ $.Values.azureDNS.hostedZoneName }}
            managedIdentity:
              clientID: {{ $.Values.azureDNS.managedIdentity.clientID }}
      {{- else }}
      - http01:
          ingress:
            class: {{ $issuer.class }}
            ingressTemplate:
              metadata:
                labels:
                  type: "challenge"
                annotations:
                  external-dns.alpha.kubernetes.io/ttl: "1m"
                  external-dns.alpha.kubernetes.io/target: {{ $.Values.fqdn | quote }}
      {{- end }}
{{- end }}
{{- end }}
---
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: selfsigned
spec:
  selfSigned: {}
```

- [ ] **Step 4: Render again and confirm only `istio` switched to `dns01`**

Run:
```bash
helm template cert-manager-issuers src/helm/charts/cert-manager-issuers --show-only templates/cluster-issuer.yaml > /tmp/cluster-issuer-rendered.yaml
grep -c "http01:" /tmp/cluster-issuer-rendered.yaml
grep -c "dns01:" /tmp/cluster-issuer-rendered.yaml
grep -A6 "name: letsencrypt-staging-istio$" /tmp/cluster-issuer-rendered.yaml
grep -A6 "name: letsencrypt-staging-azure$" /tmp/cluster-issuer-rendered.yaml
```
Expected: `http01:` count `4` (azure + nginx × 2 servers), `dns01:` count `2` (istio × 2 servers); the `letsencrypt-staging-istio` block shows `dns01:`/`azureDNS:`; the `letsencrypt-staging-azure` block still shows `http01:`/`ingress:`.

- [ ] **Step 5: Commit**

```bash
git add src/helm/charts/cert-manager-issuers/values.yaml src/helm/charts/cert-manager-issuers/templates/cluster-issuer.yaml
git commit -m "feat(cert-manager-issuers): add conditional dns01.azureDNS solver for the istio issuer"
```

---

### Task B: `src/helm/modules/cert-manager` — Workload Identity wiring

**Files:**
- Modify: `src/helm/modules/cert-manager/variables.tf`
- Modify: `src/helm/modules/cert-manager/main.tf`

**Interfaces:**
- Consumes: chart value paths from Task A (`azureDNS.subscriptionID`, `azureDNS.resourceGroupName`, `azureDNS.hostedZoneName`, `azureDNS.managedIdentity.clientID`).
- Produces: module variables `identity_client_id`, `subscription_id`, `dns_zone_resource_group`, `dns_zone_name` (consumed by Task C's `module "cert_manager"` call).

- [ ] **Step 1: Add the new variables**

Edit `src/helm/modules/cert-manager/variables.tf`:

```hcl
variable "fqdn" {
  type = string
}

variable "identity_client_id" {
  type = string
}

variable "subscription_id" {
  type = string
}

variable "dns_zone_resource_group" {
  type = string
}

variable "dns_zone_name" {
  type = string
}
```

- [ ] **Step 2: Wire Workload Identity into `helm_release.cert_manager` and DNS params into `helm_release.cert_manager_issuers`**

Edit `src/helm/modules/cert-manager/main.tf`:

```hcl
resource "helm_release" "cert_manager" {
  chart            = "${path.module}/../../charts/cert-manager"
  name             = "cert-manager"
  namespace        = "cert-manager"
  create_namespace = true
  atomic           = true

  set = [
    {
      name  = "installCRDs"
      value = "true"
    },
    {
      name  = "serviceAccount.annotations.azure\\.workload\\.identity/client-id"
      value = var.identity_client_id
    },
    {
      name  = "podLabels.azure\\.workload\\.identity/use"
      value = "true"
      type  = "string"
    }
  ]
}

resource "helm_release" "cert_manager_issuers" {
  chart            = "${path.module}/../../charts/cert-manager-issuers"
  name             = "cert-manager-issuers"
  namespace        = "cert-manager"
  create_namespace = true
  atomic           = true

  set = [
    {
      name  = "fqdn"
      value = var.fqdn
    },
    {
      name  = "azureDNS.subscriptionID"
      value = var.subscription_id
    },
    {
      name  = "azureDNS.resourceGroupName"
      value = var.dns_zone_resource_group
    },
    {
      name  = "azureDNS.hostedZoneName"
      value = var.dns_zone_name
    },
    {
      name  = "azureDNS.managedIdentity.clientID"
      value = var.identity_client_id
    }
  ]

  depends_on = [
    helm_release.cert_manager
  ]
}
```

- [ ] **Step 3: Validate the module in isolation**

Run:
```bash
cd src/helm/modules/cert-manager
terraform init -backend=false
terraform validate
```
Expected: `Success! The configuration is valid.` (This module has no provider config of its own beyond what a caller supplies; `terraform validate` here only checks HCL syntax/variable references — the real check is Task C's `terraform validate` on the full example.)

- [ ] **Step 4: Commit**

```bash
git add src/helm/modules/cert-manager/variables.tf src/helm/modules/cert-manager/main.tf
git commit -m "feat(cert-manager module): wire Workload Identity and DNS01 params through to the chart"
```

---

### Task C: `examples/cluster_argocd_ingress_istio` — federated identity, role assignment, module call

**Files:**
- Modify: `examples/cluster_argocd_ingress_istio/main.tf`

**Interfaces:**
- Consumes: `src/active-directory/workload-identity` module outputs `client_id`/`principal_id` (same module already used for `external_dns_workload_identity`/`external_secrets_workload_identity`); `src/helm/modules/cert-manager` variables from Task B; root-level `data.azurerm_dns_zone.default`, `data.azurerm_subscription.current`, `local.dns_zone`, `local.dns_zone_resource_group_name` (all already defined in `examples/common/variables.tf`, symlinked as `variables.tf`).

- [ ] **Step 1: Add the federated identity and DNS Zone Contributor role assignment**

In `examples/cluster_argocd_ingress_istio/main.tf`, insert this block immediately before the existing `module "cert_manager"` block:

```hcl
module "cert_manager_workload_identity" {
  count  = local.install_cert_manager ? 1 : 0
  source = "../../src/active-directory/workload-identity"

  name                 = "${local.cluster_name}-cert-manager"
  resource_group       = azurerm_resource_group.default
  oidc_issuer_url      = module.aks.oidc_issuer_url
  namespace            = "cert-manager"
  service_account_name = "cert-manager"
}

resource "azurerm_role_assignment" "cert_manager_dns_contributor_on_dns_zone" {
  count = local.install_cert_manager ? 1 : 0

  role_definition_name = "DNS Zone Contributor"
  principal_id         = module.cert_manager_workload_identity[0].principal_id
  scope                = data.azurerm_dns_zone.default.id
}
```

- [ ] **Step 2: Pass the new variables into `module "cert_manager"`**

Replace the existing `module "cert_manager"` block with:

```hcl
module "cert_manager" {
  count  = local.install_cert_manager ? 1 : 0
  source = "../../src/helm/modules/cert-manager"

  fqdn                    = local.cert_manager_fqdn
  identity_client_id      = module.cert_manager_workload_identity[0].client_id
  subscription_id         = data.azurerm_subscription.current.subscription_id
  dns_zone_resource_group = local.dns_zone_resource_group_name
  dns_zone_name           = local.dns_zone

  depends_on = [
    module.aks,
    azurerm_role_assignment.cert_manager_dns_contributor_on_dns_zone
  ]
}
```

- [ ] **Step 3: Validate**

Run:
```bash
cd examples/cluster_argocd_ingress_istio
terraform init -backend=false
terraform validate
```
Expected: `Success! The configuration is valid.`

- [ ] **Step 4: `terraform fmt` and diff check**

Run:
```bash
cd /home/silvios/git/azure-kubernetes
terraform fmt examples/cluster_argocd_ingress_istio/main.tf
git diff -w examples/cluster_argocd_ingress_istio/main.tf
```
Expected: the `-w` (ignore-whitespace) diff shows only the two new blocks and the `module "cert_manager"` argument changes — no unrelated reformatting.

- [ ] **Step 5: Commit**

```bash
git add examples/cluster_argocd_ingress_istio/main.tf
git commit -m "feat(istio example): federate cert-manager identity and grant DNS Zone Contributor"
```

---

### Task D: `istio-gateway` chart — wildcard certificate + Gateway-level redirect

**Files:**
- Modify: `src/helm/charts/istio-gateway/templates/certificate.yaml`
- Modify: `src/helm/charts/istio-gateway/templates/gateway.yaml`

**Interfaces:**
- Consumes: `Values.dns.cname`, `Values.dns.domain`, `Values.certificate.type`, `Values.certificate.server`, `Values.secret.prefix`, `Values.certificate.list` (all pre-existing chart values, unchanged names/shapes; `Values.certificate.list` keeps its current role of enumerating extra Gateway hosts — see Step 1 note — but stops driving per-host `Certificate`/secret generation).
- Produces: single `Certificate` named `ingress-wildcard`, `Secret` `{{ Values.secret.prefix }}wildcard` (used by every `Gateway`'s HTTPS listener); every `Gateway`'s HTTP listener sets `tls.httpsRedirect: true`.

- [ ] **Step 1: Replace the per-host `Certificate` resources with one wildcard `Certificate`**

Decision (resolves the spec's open question): `Values.certificate.list` is **kept** — it still drives which extra per-host `Gateway`/`VirtualService` pairs get created (each host still needs its own `Gateway` listener with its own `hosts:` entry) — but it no longer drives `Certificate` or secret-name generation. There is exactly one `Certificate` and one TLS secret now, shared by every `Gateway`.

Replace the full contents of `src/helm/charts/istio-gateway/templates/certificate.yaml` with:

```yaml
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: ingress-wildcard
spec:
  commonName: "*.{{ $.Values.dns.cname }}.{{ $.Values.dns.domain }}"

  dnsNames:
    - "*.{{ $.Values.dns.cname }}.{{ $.Values.dns.domain }}"

  secretName: {{ $.Values.secret.prefix }}wildcard

  issuerRef:
    kind: ClusterIssuer
    name: {{ $.Values.certificate.type }}-{{ $.Values.certificate.server }}-istio
```

- [ ] **Step 2: Point every `Gateway`'s HTTPS listener at the wildcard secret and set `httpsRedirect: true` on every HTTP listener**

Replace the full contents of `src/helm/charts/istio-gateway/templates/gateway.yaml` with:

```yaml
---
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: public-ingress-gateway
spec:
  selector:
    istio: ingress

  servers:
    - port:
        number: 80
        name: http
        protocol: HTTP
      hosts:
        - "gateway.{{ $.Values.dns.cname }}.{{ $.Values.dns.domain }}"
      tls:
        httpsRedirect: true

    - port:
        number: 443
        name: https
        protocol: HTTPS
      hosts:
        - "gateway.{{ $.Values.dns.cname }}.{{ $.Values.dns.domain }}"
      tls:
        mode: SIMPLE
        credentialName: {{ $.Values.secret.prefix }}wildcard

{{- range $cname := .Values.certificate.list }}
---
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: public-ingress-{{ $cname }}
spec:
  selector:
    istio: ingress

  servers:
    - port:
        number: 80
        name: http
        protocol: HTTP
      hosts:
        - "{{ $cname }}.{{ $.Values.dns.cname }}.{{ $.Values.dns.domain }}"
      tls:
        httpsRedirect: true

    - port:
        number: 443
        name: https
        protocol: HTTPS
      hosts:
        - "{{ $cname }}.{{ $.Values.dns.cname }}.{{ $.Values.dns.domain }}"
      tls:
        mode: SIMPLE
        credentialName: {{ $.Values.secret.prefix }}wildcard
{{- end }}
```

- [ ] **Step 3: Render and verify**

Run:
```bash
helm template istio-ingress src/helm/charts/istio-gateway \
  --set dns.cname=29awz --set dns.domain=sandbox.wasp.silvios.me \
  --set certificate.type=letsencrypt --set certificate.server=staging \
  --show-only templates/certificate.yaml --show-only templates/gateway.yaml
```
Expected: exactly one `kind: Certificate` block (`name: ingress-wildcard`, `commonName: "*.29awz.sandbox.wasp.silvios.me"`); three `kind: Gateway` blocks (`public-ingress-gateway`, `public-ingress-argocd`, `public-ingress-httpbin`), each with `credentialName: ingress-tls-wildcard` and `httpsRedirect: true` on the HTTP listener. Confirm the count:

```bash
helm template istio-ingress src/helm/charts/istio-gateway \
  --set dns.cname=29awz --set dns.domain=sandbox.wasp.silvios.me \
  --show-only templates/certificate.yaml | grep -c "^kind: Certificate"
```
Expected: `1`.

- [ ] **Step 4: Commit**

```bash
git add src/helm/charts/istio-gateway/templates/certificate.yaml src/helm/charts/istio-gateway/templates/gateway.yaml
git commit -m "feat(istio-gateway chart): single wildcard Certificate, Gateway-level HTTPS redirect"
```

---

### Task E: Remove the manual VirtualService redirects (istio-gateway + httpbin)

**Files:**
- Modify: `src/helm/charts/istio-gateway/templates/virtualservice.yaml`
- Modify: `src/helm/charts/httpbin/templates/istio/virtualservice-public.yaml`

**Interfaces:**
- Consumes: Task D's `httpsRedirect: true` on every `Gateway`'s HTTP listener (the whole point of this task is that the Gateway now redirects before any VirtualService is evaluated, so the manual `match`+`redirect` block is dead code once Task D has shipped).

- [ ] **Step 1: Confirm the manual redirect is now redundant (still present at this point — "red" baseline)**

Run:
```bash
grep -c "redirectCode: 302" src/helm/charts/istio-gateway/templates/virtualservice.yaml src/helm/charts/httpbin/templates/istio/virtualservice-public.yaml
```
Expected: `2` and `1` respectively (both VS files still have the block).

- [ ] **Step 2: Remove the redirect `match` block from both VirtualServices in `istio-gateway`**

Replace the full contents of `src/helm/charts/istio-gateway/templates/virtualservice.yaml` with:

```yaml
{{- if .Values.gatewayVirtualService.enabled }}
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: gateway-virtual-service-public
spec:
  hosts:
    - gateway.{{ $.Values.dns.cname }}.{{ $.Values.dns.domain }}

  gateways:
    - public-ingress-gateway

  http:
    - name: gateway-health
      headers:
        request:
          add:
            X-A1-origin-1: public-ingress-gateway

      directResponse:
        status: 200
        body:
          string: {{ printf "%s\n" .Values.gatewayVirtualService.body | quote }}
{{- end }}

---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: argocd-virtual-service-public
spec:
  hosts:
    - argocd.{{ $.Values.dns.cname }}.{{ $.Values.dns.domain }}

  gateways:
    - public-ingress-argocd

  http:
    - name: argocd
      headers:
        request:
          add:
            X-A1-origin-1: public-ingress-argocd

      route:
        - destination:
            host: argocd-server.argocd.svc.cluster.local
            port:
              number: 80
```

- [ ] **Step 3: Remove the redirect `match` block from the httpbin VirtualService**

Replace the full contents of `src/helm/charts/httpbin/templates/istio/virtualservice-public.yaml` with:

```yaml
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: httpbin-virtual-service-public
spec:
  hosts:
    - httpbin.{{ .Values.dns.cname }}.{{ .Values.dns.domain }}

  gateways:
    - istio-ingress/public-ingress-httpbin

  http:
    - name: httpbin
      headers:
        request:
          add:
            X-W1-gateway: public-ingress-httpbin

      route:
        - destination:
            host: httpbin.{{ .Release.Namespace }}.svc.cluster.local
            port:
              number: {{ .Values.service.port }}
```

- [ ] **Step 4: Verify the redirect block is gone and the remaining routes are untouched**

Run:
```bash
grep -c "redirectCode: 302" src/helm/charts/istio-gateway/templates/virtualservice.yaml src/helm/charts/httpbin/templates/istio/virtualservice-public.yaml
helm template istio-ingress src/helm/charts/istio-gateway \
  --set dns.cname=29awz --set dns.domain=sandbox.wasp.silvios.me \
  --show-only templates/virtualservice.yaml | grep -A3 "name: argocd$"
helm template httpbin src/helm/charts/httpbin \
  --set dns.cname=29awz --set dns.domain=sandbox.wasp.silvios.me \
  --show-only templates/istio/virtualservice-public.yaml | grep -A3 "name: httpbin$"
```
Expected: the `grep -c` prints `0` and `0`; both `helm template` calls show the `route:`/`destination:` block directly (no `match:`/`redirect:` above them).

- [ ] **Step 5: Commit**

```bash
git add src/helm/charts/istio-gateway/templates/virtualservice.yaml src/helm/charts/httpbin/templates/istio/virtualservice-public.yaml
git commit -m "fix(istio): drop manual HTTP redirect now that the Gateway redirects natively"
```

---

### Task F: Live validation against `wasp-sandbox-29awz`

**Files:** none (validation only — no code changes expected; if validation surfaces a bug, fix it in the file it belongs to and fold that fix into this task's commit).

**Interfaces:** none — this task consumes the finished state of Tasks A–E against the live cluster referenced in `HANDOFF.local.md`.

- [ ] **Step 1: Confirm the cluster is still live and get credentials**

Run:
```bash
az aks show --resource-group wasp-sandbox-29awz --name wasp-sandbox-29awz --query "provisioningState" -o tsv
az aks get-credentials --resource-group wasp-sandbox-29awz --name wasp-sandbox-29awz --admin --overwrite-existing
```
If the cluster no longer exists, stop here and tell the user — re-provisioning (`terraform apply` in `examples/cluster_argocd_ingress_istio`, ~9 min per `HANDOFF.md`) is a decision for them, not an automatic fallback.

- [ ] **Step 2: `terraform plan` the full example and inspect the plan before applying**

Run:
```bash
cd examples/cluster_argocd_ingress_istio
terraform plan -out=/tmp/dns01-migration.tfplan
terraform show /tmp/dns01-migration.tfplan | grep -E "^\s*# (module\.cert_manager|azurerm_role_assignment\.cert_manager)"
```
Expected: new resources for `module.cert_manager_workload_identity[0]`, `azurerm_role_assignment.cert_manager_dns_contributor_on_dns_zone[0]`, and in-place updates to the two `cert-manager`/`cert-manager-issuers` `helm_release`s and the `istio-gateway` `helm_release`. **Stop and ask the user** if the plan proposes a destroy/recreate (`-replace`-shaped diff) of `module.ingress_istio[0].helm_release.istio_gateway`'s underlying Service — per `CLAUDE.md`'s "Gotchas operacionais", that would recreate the LoadBalancer and change the public IP.

- [ ] **Step 3: Apply (ask the user first — this touches the live cluster)**

Run only after explicit user confirmation:
```bash
terraform apply /tmp/dns01-migration.tfplan
```

- [ ] **Step 4: Confirm the wildcard `Certificate` issued via DNS01**

Run:
```bash
kubectl get certificate ingress-wildcard -n istio-ingress -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}'
kubectl describe certificate ingress-wildcard -n istio-ingress
```
Expected: `True`; the `describe` output's events show a `CertificateRequest`/`Order`/`Challenge` chain of type `dns01`, not `http01`.

- [ ] **Step 5: Confirm the DNS Zone Contributor identity actually writes to the zone (not just reads)**

During Step 4's certificate issuance, in a separate terminal, poll the zone for the transient TXT record:
```bash
watch -n5 'az network dns record-set txt list --resource-group <dns-zone-resource-group> --zone-name <dns-zone-name> --query "[?contains(name, \x27_acme-challenge\x27)].name" -o tsv'
```
Expected: a `_acme-challenge.29awz` (or similar) TXT record appears during issuance and disappears once the `Challenge` completes — proof of write access, matching the same validation approach already documented in `CLAUDE.md` for `external-dns`.

- [ ] **Step 6: Confirm all three hosts serve valid TLS and redirect from HTTP**

Run:
```bash
for h in gateway argocd httpbin; do
  echo "$h:"
  curl -sk -o /dev/null -w "  https -> %{http_code}\n" "https://$h.29awz.sandbox.wasp.silvios.me"
  curl -sI "http://$h.29awz.sandbox.wasp.silvios.me" | head -1
done
```
Expected: `https -> 200` for all three; the `http://` request returns a `301`/`302` status line (now emitted by the Gateway, not a VirtualService).

- [ ] **Step 7: Confirm the wildcard covers new hosts without re-issuing**

Run:
```bash
kubectl get certificaterequests -n istio-ingress
curl -sk -o /dev/null -w "%{http_code}\n" "https://foo.29awz.sandbox.wasp.silvios.me" --resolve foo.29awz.sandbox.wasp.silvios.me:443:$(dig +short gateway.29awz.sandbox.wasp.silvios.me | head -1)
kubectl get certificaterequests -n istio-ingress
```
Expected: the `certificaterequests` list is identical before and after the `curl` to the never-before-seen `foo.` host — no new `CertificateRequest` was triggered, proving the wildcard covers it.

- [ ] **Step 8: Update `HANDOFF.local.md`**

Move this migration out of "In Progress"/"Next Steps" into a "Completed" section, noting the commits and the live validation results from Steps 4–7.

- [ ] **Step 9: Commit the HANDOFF update**

```bash
git add HANDOFF.local.md
git commit -m "docs: record cert-manager DNS01 migration as validated against wasp-sandbox-29awz"
```

---

## Self-Review Notes

- **Spec coverage:** Design §1 (Terraform identity) → Task C. §2 (cert-manager module wiring) → Task B. §3 (issuers chart solver) → Task A. §4 (wildcard cert + Gateway redirect + VS cleanup) → Tasks D and E. §5 (validation) → Task F. The spec's two open questions are resolved explicitly: `certificate.list` is kept (Task D, Step 1) for per-host Gateway/VS enumeration only; the "validate the three hosts in the same window" risk is addressed by Task F applying Tasks D+E together in one `terraform apply` (Step 3), never partially.
- **Placeholder scan:** every step has literal file contents or literal shell commands; no "TBD"/"similar to Task N".
- **Type/name consistency checked:** `identity_client_id`/`subscription_id`/`dns_zone_resource_group`/`dns_zone_name` (Task B variables) match the exact names used in Task C's `module "cert_manager"` call; `azureDNS.*` value paths (Task A) match the `set` block names in Task B; `Values.secret.prefix}}wildcard` (Task D) matches the `secretName`/`credentialName` used across `certificate.yaml` and `gateway.yaml`; the `ClusterIssuer` name `{{ certificate.type }}-{{ certificate.server }}-istio` (Task D's `certificate.yaml`) matches the name actually rendered by Task A's `cluster-issuer.yaml` (`letsencrypt-staging-istio` for the example's `cert_manager_issuer_type`/`_server` locals).
