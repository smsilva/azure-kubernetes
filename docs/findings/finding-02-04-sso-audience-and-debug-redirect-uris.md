# #2/#4 — SSO do ArgoCD: audience pessoal + redirect URIs de debug

- **Severidade:** #2 🔴 alta · #4 🟠 média
- **Onde:** `src/active-directory/app-registration/main.tf:13` (#2) e `:20-25` (#4)
- **Status:** aberto

## #2 — `sign_in_audience = "AzureADandPersonalMicrosoftAccount"`

```hcl
resource "azuread_application" "default" {
  ...
  sign_in_audience = "AzureADandPersonalMicrosoftAccount"
```

Essa propriedade controla quem consegue completar o fluxo OAuth desse App
Registration (o SSO do ArgoCD). Valores possíveis, do mais restrito ao mais
aberto:

| Valor | Quem consegue logar |
| --- | --- |
| `AzureADMyOrg` | só contas do tenant próprio |
| `AzureADMultipleOrgs` | contas de qualquer tenant Azure AD |
| `AzureADandPersonalMicrosoftAccount` (atual) | qualquer tenant Azure AD **+ contas Microsoft pessoais** (outlook.com, hotmail.com, Xbox, Skype…) |
| `PersonalMicrosoftAccount` | só contas pessoais |

Na prática, qualquer pessoa com uma conta @outlook.com/@hotmail.com consegue
chegar na tela de login do ArgoCD, mesmo sem nenhuma relação com o tenant.

**Por que não é (necessariamente) um vazamento completo:** o ArgoCD autoriza
por **grupos** (`argocd_administrators_ids`/`argocd_contributors_ids` em
`examples/common/variables.tf`), não por "autenticou = tem acesso". Uma conta
pessoal não pertence a nenhum grupo do tenant, então não deveria receber RBAC
nenhum dentro do ArgoCD — mas isso depende inteiramente da política RBAC do
ArgoCD estar correta (`policy.default` sem privilégio, mapeamento de grupos
explícito). Restringir a audience é defesa em profundidade: elimina a classe
inteira de "conta pessoal chega na tela de login", independente de qualquer
bug futuro na política RBAC.

**Correção:** trocar para `AzureADMyOrg`.

## #4 — `redirect_uris` incluem endpoints de debug

```hcl
redirect_uris = [
  "https://argocd.${var.dns_zone}/auth/callback",
  "https://${local.azuread_application_url}/auth/callback",
  "https://oidcdebugger.com/debug",       # <- remover
  "http://localhost/auth/callback",       # <- remover
]
```

`https://oidcdebugger.com/debug` é um serviço de terceiros usado para inspecionar
o fluxo OAuth durante desenvolvimento; `http://localhost/auth/callback` é um
callback HTTP (não HTTPS) para teste local. Nenhum dos dois tem lugar num
ambiente real: um redirect URI registrado é, por definição, um destino
confiável do `code`/`token` da autenticação. Manter esses dois amplia
desnecessariamente a superfície — inclusive um domínio de terceiros que o
projeto não controla.

**Correção:** remover as duas entradas, mantendo só os dois callbacks do
ArgoCD.

## Como validar

Os dois achados mudam o comportamento observável do SSO, então não dá para
confirmar só com `terraform plan`/`validate`:

1. Aplicar a mudança contra um cluster vivo (o atual foi destruído — precisa
   provisionar um novo, ver `HANDOFF.local.md`).
2. Fazer logout na UI do ArgoCD e logar de novo via SSO, confirmando que o
   fluxo com uma conta do tenant (`silvios.me`) continua funcionando —
   `GET /api/v1/settings` sozinho não é suficiente, porque ele só reporta a
   config estática, não se o login de fato completa.
3. Confirmar que `sign_in_audience = AzureADMyOrg` não quebra nenhum caso de
   uso legítimo hoje (não há motivo de negócio conhecido para permitir
   contas pessoais ou outros tenants).
