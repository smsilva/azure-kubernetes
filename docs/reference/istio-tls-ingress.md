# Istio ingress + TLS (exemplo `cluster_argocd_ingress_istio`)

## Como o certificado é emitido hoje

`src/helm/charts/istio-gateway/templates/certificate.yaml` emite **um único**
`Certificate` `ingress-wildcard`:

- host: `*.<cluster-random-id>.<dns-zone>` (ex.: `*.vpd54.sandbox.wasp.silvios.me`)
- secret: `ingress-tls-wildcard`, no namespace `istio-ingress`
- issuer: `ClusterIssuer letsencrypt-staging-istio`, `dns01.azureDNS` via Workload
  Identity federada (`DNS Zone Contributor` na DNS Zone — mesmo padrão do external-dns)

Todos os `Gateway` (`public-ingress-gateway`, `public-ingress-argocd`,
`public-ingress-httpbin`) usam esse secret como `credentialName` e têm
`tls.httpsRedirect: true` no listener HTTP.

O `<cluster-random-id>` vem de `random_string.id` (`examples/common/variables.tf`)
e é **regenerado a cada apply**.

## Cuidados

- **O certificado é wildcard, o roteamento SNI não.** Cada `Gateway` só aceita SNI
  para os hosts listados em `hosts:`. Um host novo não cadastrado em nenhum Gateway
  falha o handshake TLS mesmo coberto pelo wildcard. Comportamento normal do Istio.
- **Wildcard cobre um label só.** `*.sandbox.wasp.silvios.me` NÃO cobre
  `argocd.vpd54.sandbox.wasp.silvios.me`; `*.*.` não é emitido pela Let's Encrypt.
  Não existe um certificado estável "do domínio base" que sirva aos hosts do cluster.
- Certificado é **Let's Encrypt STAGING** → `curl` HTTPS falha na verificação da CA.
  Testar com `curl -k`; não é bug.
- Roteamento externo do ArgoCD vem do chart `istio-gateway` (Gateway
  `public-ingress-argocd` + VirtualService no namespace `istio-ingress`), NÃO do
  `argo-cd-config`. Não procurar VS/Gateway do argocd no namespace `argocd`.
- **Nunca** usar `-replace` em `module.ingress_istio[0].helm_release.istio_gateway`
  num cluster em uso: destroy+create recria o Service LoadBalancer, muda o IP público
  e derruba os três hosts até o external-dns reescrever o A record. Para validar
  mudança de template, aplicar o objeto de `helm template` via `kubectl` com
  `app.kubernetes.io/managed-by: Helm` + annotations `meta.helm.sh/release-{name,namespace}`
  (um upgrade futuro o adota sem erro de ownership).
- Os templates autorais do chart (`gateway.yaml`, `virtualservice.yaml`,
  `certificate.yaml`) **não** são sobrescritos por `scripts/update-local-helm-charts-istio`
  — o script só troca os `.tgz` dos subcharts.
- Tudo sob a chave `gateway:` do `values.yaml` é repassado ao subchart `istio/gateway`,
  cujo `values.schema.json` rejeita propriedades desconhecidas. Valores próprios do
  repo precisam de chave de topo (ex.: `gatewayVirtualService`).

## Aberto: reaproveitar o certificado entre recriações

**Problema.** A private key/secret TLS só existe dentro do cluster. Cada recriação
reemite do zero e gasta orçamento ACME sem necessidade.

**Direção acordada (não implementada).** Opt-in por parâmetro: informar as chaves do
Key Vault foundation que guardam cert + key em base64. Se informadas, o `Secret` TLS
é semeado no provisionamento e o cert-manager adota o material existente em vez de
emitir; se omitidas, o fluxo atual (emissão normal) continua valendo.

Só rende economia quando o host se repete — ou seja, quando o `random_string.id` for
reaproveitado. Modelo escolhido: **random como default, com id fixável por variável**
para quem quiser reusar o certificado.

**Pendente de análise:** renovação. Certificado Let's Encrypt vale 90 dias e o
cert-manager renova em ~2/3 da vida; um material persistido além dessa janela dispara
reemissão na restauração de qualquer forma, e o certificado renovado precisaria voltar
ao Key Vault para o ciclo se sustentar.
