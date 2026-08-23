# Istio ingress + TLS (`cluster_argocd_ingress_istio` example)

## How the certificate is issued today

`src/helm/charts/istio-gateway/templates/certificate.yaml` issues a **single**
`ingress-wildcard` `Certificate`:

- host: `*.<cluster-random-id>.<dns-zone>` (e.g. `*.vpd54.sandbox.wasp.silvios.me`)
- secret: `ingress-tls-wildcard`, in the `istio-ingress` namespace
- issuer: `ClusterIssuer letsencrypt-staging-istio`, `dns01.azureDNS` through
  federated Workload Identity (`DNS Zone Contributor` on the DNS Zone — same
  pattern as external-dns)

Every `Gateway` (`public-ingress-gateway`, `public-ingress-argocd`,
`public-ingress-httpbin`) uses that secret as `credentialName` and sets
`tls.httpsRedirect: true` on the HTTP listener.

The `<cluster-random-id>` comes from `random_string.id`
(`examples/common/variables.tf`) and is **regenerated on every apply**, so each
new cluster issues its own certificate.

## Caveats

- **The certificate is wildcard, SNI routing is not.** Each `Gateway` only
  accepts SNI for the hosts listed in its `hosts:`. A new host not registered in
  any Gateway fails the TLS handshake even when covered by the wildcard. Normal
  Istio behavior.
- **A wildcard covers a single label.** `*.sandbox.wasp.silvios.me` does NOT
  cover `argocd.vpd54.sandbox.wasp.silvios.me`; `*.*.` is not issued by Let's
  Encrypt. There is no stable "base domain" certificate that would serve the
  cluster's hosts.
- The certificate is **Let's Encrypt STAGING** → HTTPS `curl` fails CA
  verification. Test with `curl -k`; it is not a bug.
- External routing for ArgoCD comes from the `istio-gateway` chart (Gateway
  `public-ingress-argocd` + VirtualService in the `istio-ingress` namespace), NOT
  from `argo-cd-config`. Do not look for the argocd VS/Gateway in the `argocd`
  namespace.
- **Never** use `-replace` on `module.ingress_istio[0].helm_release.istio_gateway`
  in a cluster in use: destroy+create recreates the LoadBalancer Service, changes
  the public IP, and takes down all three hosts until external-dns rewrites the A
  record. To validate a template change, apply the object from `helm template`
  with `kubectl`, carrying `app.kubernetes.io/managed-by: Helm` + the
  `meta.helm.sh/release-{name,namespace}` annotations (a later upgrade adopts it
  without an ownership error).
- The chart's own templates (`gateway.yaml`, `virtualservice.yaml`,
  `certificate.yaml`) are **not** overwritten by
  `scripts/update-local-helm-charts-istio` — the script only swaps the subcharts'
  `.tgz`.
- Everything under the `gateway:` key of `values.yaml` is passed through to the
  `istio/gateway` subchart, whose `values.schema.json` rejects unknown
  properties. Values owned by this repo need a top-level key (e.g.
  `gatewayVirtualService`).
