# #11 — redirect HTTP→HTTPS nunca dispara no `istio-gateway`

- **Severidade:** 🟠 média
- **Onde:** `src/helm/charts/istio-gateway/templates/virtualservice.yaml` (e o
  VirtualService equivalente do httpbin)
- **Status:** aberto

## O problema

Os três hosts servidos pelo `istio-gateway` (`gateway`, `argocd`, `httpbin`)
respondem **HTTP puro com 200** em vez de redirecionar para HTTPS. O match
usado no VirtualService é:

```yaml
match:
  - uri: {...}
    scheme:
      exact: http
```

Mas isso não casa: quando o tráfego chega pela porta 80 do Gateway, o Envoy
não popula o pseudo-header `:scheme` nesse caminho (não é um proxy
HTTP-para-HTTPS transparente do jeito que `scheme: {exact: http}` pressupõe).
Resultado: a regra de redirect nunca é avaliada como verdadeira, e o tráfego
HTTP cai direto na regra de roteamento normal — servido em claro, com 200.

## A correção (hipótese, não testada)

Trocar o match de `scheme: {exact: http}` por `port: 80`: como o Gateway já
separa os listeners HTTP (80) e HTTPS (443), casar pela porta de entrada é o
sinal correto e disponível nesse ponto do pipeline, ao contrário do scheme.

Precisa ser aplicado em **dois lugares**: o VirtualService gerado pelo
`istio-gateway` (`gatewayVirtualService` em `values.yaml`) e o VirtualService
próprio do `httpbin` (que tem seu próprio redirect, fora do chart
`istio-gateway`).

## O que NÃO fazer

**Não** usar `httpsRedirect: true` direto no `Gateway` — foi evitado de
propósito: isso conflitaria com a renovação ACME HTTP01 do cert-manager, que
depende de conseguir servir `/.well-known/acme-challenge/...` em HTTP puro
para provar controle do domínio. Um redirect incondicional no Gateway
quebraria a renovação dos três certificados.

## Como validar

1. Aplicar a troca do match nos dois VirtualServices.
2. Provisionar um cluster (ou usar um vivo, se houver) e confirmar:
   - `curl -I http://<host>` retorna `301`/`302` para `https://<host>`.
   - `curl http://<host>/.well-known/acme-challenge/<token-de-teste>`
     **continua** servido em HTTP puro (sem redirect) — sem isso a renovação
     HTTP01 quebra silenciosamente na próxima expiração de certificado.
3. Repetir para os três hosts (`gateway`, `argocd`, `httpbin`), já que o
   VirtualService do httpbin é definido separadamente do resto.

Aplicar via `helm upgrade` normal (não usar `terraform apply -replace` no
`helm_release.istio_gateway` — troca de template não exige recreate, e um
replace nesse recurso recria o Service LoadBalancer, muda o IP público e
derruba os três hosts até o external-dns reescrever o A record; ver
`CLAUDE.md`, seção "Gotchas operacionais").
