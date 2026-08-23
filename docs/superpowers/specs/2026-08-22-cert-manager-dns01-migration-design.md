# Migrar cert-manager de HTTP01 para DNS01 (issuer `istio`)

- **Data:** 2026-08-22
- **Escopo:** `examples/cluster_argocd_ingress_istio` apenas (estratégia de
  migração acordada: um exemplo por vez).
- **Motivação:** achado de oportunidade do review de hardening — HTTP01
  impede certificado wildcard e obriga os VirtualServices do `istio-gateway`
  a excluir `/.well-known/acme-challenge/` do redirect via uma regex frágil
  (ver `docs/findings/finding-11-http-to-https-redirect-never-fires.md`).

## Contexto atual

- cert-manager `v1.21.1` (vendorizado em `src/helm/charts/cert-manager`),
  instalado via `src/helm/modules/cert-manager` (`helm_release.cert_manager`
  + `helm_release.cert_manager_issuers`).
- `src/helm/charts/cert-manager-issuers/templates/cluster-issuer.yaml` gera
  um `ClusterIssuer` por combinação de `server` (production/staging) ×
  `issuer` (`azure`, `nginx`, `istio`), todos com solver `http01.ingress`
  (`class: istio` para o issuer usado pelo exemplo em foco).
- `src/helm/charts/istio-gateway/templates/certificate.yaml` gera **um
  `Certificate` por host** (`gateway`, e um por item de
  `Values.certificate.list`, hoje `[argocd, httpbin]`), todos referenciando
  o `ClusterIssuer` `{{type}}-{{server}}-istio`.
- `src/helm/charts/istio-gateway/templates/virtualservice.yaml` e
  `src/helm/charts/httpbin/templates/istio/virtualservice-public.yaml` têm,
  cada um, um bloco `match: [port: 80, uri: {regex: <exclusão ACME>}] →
  redirect: https` (achado #11, já corrigido nesta forma via PR #5).
- Padrão de Workload Identity já estabelecido por `external-dns` e
  `external-secrets`: módulo `src/active-directory/workload-identity` cria
  a MI + federated credential; `azurerm_role_assignment` dá a role Azure
  necessária **escopada no recurso específico** (não no RG); o
  `client_id` é passado ao chart via `serviceAccount.annotations.azure\.workload\.identity/client-id`
  + `podLabels.azure\.workload\.identity/use: "true"`. Ver
  `examples/cluster_argocd_ingress_istio/main.tf:95-127` (bloco
  `external_dns_workload_identity`) como referência literal a replicar.
- `data.azurerm_dns_zone.default` (definido em `examples/common/variables.tf`)
  é a zone Azure DNS que o external-dns já gerencia — mesma zone a usar
  aqui.
- `local.dns_zone` = domínio da zone (ex.: `sandbox.wasp.silvios.me`);
  `local.cluster_random_id` = cname do cluster (ex.: `29awz`); os três hosts
  seguem `<host>.<cname>.<dns_zone>` (ex.:
  `gateway.29awz.sandbox.wasp.silvios.me`).

## Decisões (aprovadas em brainstorming)

1. **Certificado wildcard único**, cobrindo `*.<cname>.<dns_zone>` — substitui
   os certificados por host.
2. **Só o issuer `istio` muda** para DNS01. Os issuers `azure` e `nginx`
   continuam `http01` — fora do escopo (exemplos legado não migrados).
3. **Redirect HTTP→HTTPS passa a ser feito pelo Gateway**
   (`tls.httpsRedirect: true` no listener HTTP), não mais por
   `match`+`redirect` manual nos VirtualServices. Sem HTTP01, não há mais
   necessidade de servir `/.well-known/acme-challenge/` em HTTP puro, então
   a ressalva "não usar `httpsRedirect: true`" (ver `CLAUDE.md`, achado #11)
   deixa de se aplicar **depois** que a migração para DNS01 estiver completa
   — não antes, e não parcialmente.
4. **Autenticação via Workload Identity federada** (não Service Principal
   com secret) — mesmo padrão de `external-dns`/`external-secrets`. Mesma
   `data.azurerm_dns_zone.default`, role `DNS Zone Contributor` escopada na
   zone.
5. Sem webhook externo — usar o solver nativo `dns01.azureDNS` já suportado
   pelo cert-manager v1.21.1 vendorizado (confirmado no CRD
   `crd-cert-manager.io_clusterissuers.yaml:329-410`: campos `clientID`,
   `hostedZoneName`, `resourceGroupName`, `subscriptionID`,
   `managedIdentity.clientID`).

## Design

### 1. Terraform — nova identidade federada

Em `examples/cluster_argocd_ingress_istio/main.tf`, replicar o bloco de
`external_dns_workload_identity`/`azurerm_role_assignment.external_dns_contributor_on_dns_zone`
para o cert-manager:

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
  principal_id          = module.cert_manager_workload_identity[0].principal_id
  scope                = data.azurerm_dns_zone.default.id
}
```

O `module "cert_manager"` passa a receber os novos parâmetros (client_id,
tenant, subscription, RG da zone, nome da zone) e depende do role
assignment, no mesmo padrão do `external_dns`.

### 2. `src/helm/modules/cert-manager` — novas variáveis e wiring

`variables.tf` ganha: `identity_client_id`, `tenant_id`, `subscription_id`,
`dns_zone_resource_group`, `dns_zone_name`.

`helm_release.cert_manager` ganha os `set` de
`serviceAccount.annotations.azure\.workload\.identity/client-id` e
`podLabels.azure\.workload\.identity/use` (idêntico ao `external-dns`).

`helm_release.cert_manager_issuers` ganha `set` para propagar
`azureDNS.subscriptionID`, `azureDNS.resourceGroupName`,
`azureDNS.hostedZoneName`, `azureDNS.managedIdentity.clientID` ao chart
`cert-manager-issuers`.

### 3. `src/helm/charts/cert-manager-issuers` — solver DNS01 no issuer `istio`

`values.yaml`: o item `{name: istio, class: istio}` da lista `issuers`
ganha um campo `solver: dns01` (default `http01` para não afetar
`azure`/`nginx`); mais os campos `azureDNS.*` citados acima.

`templates/cluster-issuer.yaml`: o loop de `issuers` passa a escolher o
bloco `solvers` condicionalmente —

```yaml
solvers:
  {{- if eq $issuer.solver "dns01" }}
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
```

(sintaxe exata a ajustar durante a implementação; o ponto fixo é: solver
condicional por issuer, sem afetar `azure`/`nginx`.)

### 4. `src/helm/charts/istio-gateway` — certificado wildcard + redirect no Gateway

`templates/certificate.yaml`: substituir os N `Certificate` (um por host)
por **um único**:

```yaml
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

`Values.certificate.list` deixa de existir (ou passa a servir só para
metadados/documentação — a confirmar no plano); os `Gateway`s referenciam
`{{ $.Values.secret.prefix }}wildcard` no lugar dos secrets por host.

`templates/gateway.yaml`: listener HTTP (porta 80) ganha `tls.httpsRedirect: true`.

`templates/virtualservice.yaml` e o VS do httpbin: **remover** o bloco
`match: [port: 80, ...] → redirect: https` inteiro — o Gateway já
redireciona antes do VS ser avaliado.

### 5. Validação (contra o cluster vivo `wasp-sandbox-29awz`, se ainda de pé)

1. `kubectl describe certificate ingress-wildcard -n istio-ingress` →
   `Ready=True`, evento de challenge tipo `dns01`.
2. Confirmar na zone Azure DNS que o registro `TXT
   _acme-challenge.<cname>.<dns_zone>` foi criado durante a emissão e
   removido depois (prova de que a MI federada tem escrita real, não só
   leitura — mesmo cuidado já documentado no `CLAUDE.md` para o
   external-dns).
3. `curl -k https://<host>` nos três hosts → `200`.
4. `curl -I http://<host>` nos três hosts → `301`/`302` (agora emitido pelo
   Gateway, não pelo VS).
5. Emitir um host novo qualquer sob o mesmo wildcard (ex.: criar um VS de
   teste para `foo.<cname>.<dns_zone>`) e confirmar que **não** dispara
   nova emissão de certificado — prova de que o wildcard cobre hosts novos
   sem reemissão.
6. Aplicar via `terraform apply` normal (a mudança de chart/CRD/solver não
   é um replace destrutivo do `helm_release.istio_gateway`, mas confirmar
   o plano antes — se o Terraform propuser `-replace` implícito no Service
   do Gateway, investigar antes de aplicar; ver `CLAUDE.md`, "Gotchas
   operacionais").

## Fora de escopo

- Issuers `azure` e `nginx` (exemplos legado, http01 mantido).
- Qualquer mudança em `examples/cluster_argocd_ingress_azure`,
  `_nginx`, `cluster_one_nodepool`, `cluster_two_nodepools`.
- Renovação automática/monitoramento de expiração do certificado wildcard
  (fora do escopo desta migração; comportamento padrão do cert-manager já
  cobre renovação).

## Riscos / pontos de atenção

- **Corte de continuidade do certificado:** trocar de N certs por host
  para 1 wildcard invalida os secrets atuais
  (`{{prefix}}gateway`, `{{prefix}}argocd`, `{{prefix}}httpbin`). Os hosts
  ficarão momentaneamente sem TLS válido até o novo `Certificate` emitir
  (ordem de minutos, LE staging). Não é um problema para o cluster de
  sandbox atual, mas deve ser sinalizado se algum dia isso rodar contra um
  ambiente com tráfego real.
- **`httpsRedirect: true` no Gateway** muda o comportamento de TODOS os
  hosts que passam por esse Gateway simultaneamente — não há como fazer
  rollout gradual por host. Validar os três hosts na mesma janela de
  mudança.
- Confirmar que o cert-manager v1.21.1 vendorizado realmente inclui o
  RBAC/CRD necessário para `managedIdentity` no `dns01.azureDNS` (já
  confirmado no CRD nesta sessão — mas revalidar no `helm template` antes
  de aplicar).
