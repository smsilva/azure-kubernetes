# azure-kubernetes

Módulos Terraform para provisionar AKS com stack GitOps (ArgoCD) e opções de
ingress (Istio, NGINX, Application Gateway).

## Estrutura

- `src/` — módulos Terraform reutilizáveis, **compartilhados entre os exemplos**
  - `cluster`, `nodepool`, `application-gateway`
  - `active-directory/{app-registration,workload-identity,cluster-access-group}`
  - `helm/modules/*` — wrappers `helm_release`
  - `helm/charts/*` — charts locais (vendored via `helm fetch`)
- `examples/` — 5 exemplos que consomem `src/`; `examples/common/` é compartilhado
  por symlink (`variables.tf`, `secrets.tf`, `network.tf`)
- `scripts/` — utilitários
- `docs/reference/` — conhecimento operacional por tema (ler antes de mexer na área)

## ⚠️ Antes de editar um módulo compartilhado

Cada exemplo pina uma versão diferente de provider; `src/*` é comum aos 5.
**Editar um módulo compartilhado afeta todos.** Só o `cluster_argocd_ingress_istio`
está migrado (azurerm v5 / helm v3); os outros 4 estão legado e alguns já não passam
em `terraform validate` — isso é esperado, não regressão.

→ `docs/reference/provider-migration.md` (tabela de versões, incompatibilidades,
estratégia de migração)

## Referência por tema

| Área | Arquivo |
|---|---|
| Versões de provider, migração | `docs/reference/provider-migration.md` |
| Istio ingress, TLS, cert-manager | `docs/reference/istio-tls-ingress.md` |
| ArgoCD: SSO, RBAC, app-of-apps | `docs/reference/argocd.md` |
| external-secrets, external-dns | `docs/reference/workload-identity.md` |
| Terraform/Azure, permissões, CI | `docs/reference/terraform-azure.md` |

Estado da migração e próximos passos: `HANDOFF.md` (e `HANDOFF.local.md`, local).

## Convenções

- Rodar `terraform fmt` antes de commitar. Cuidado: `terraform fmt -recursive examples`
  segue os symlinks de `examples/common/` e normaliza o arquivo inteiro — conferir com
  `git diff -w` antes de commitar junto de mudança funcional.
- Validar com `terraform init -backend=false && terraform validate` (não requer credenciais).
- Renderizar templates com `templatefile()` dentro de um `locals`. **Não** reintroduzir
  `data "template_file"`: o provider `hashicorp/template` foi arquivado e não tem build
  `darwin_arm64`.
- `.terraform.lock.hcl` NÃO é versionado.
- Charts locais: não bumpar `Chart.yaml version` por edição só de template (sem mudança
  de subchart/`appVersion`).

## Convenções de documentação

`CLAUDE.md`, `HANDOFF.md` e `HANDOFF.local.md` entram no contexto de toda sessão —
mantê-los **curtos**.

- `CLAUDE.md` = mapa + convenções + ponteiros. Uma linha por item; explicação longa
  vai para `docs/reference/<tema>.md`.
- `HANDOFF*.md` = só o estado atual: o que está em progresso, o que está quebrado,
  como retomar, próximos passos. Sem histórico — concluído vai para `CHANGELOG.md`
  ou `docs/migration-progress.md`.
- Nada de narrativa de sessão ("fixes desta sessão", "RESOLVIDO em <data>"). Se o
  problema acabou, a nota some; se virou comportamento novo, vira uma linha
  descritiva no `docs/reference/` correspondente.
- Criar arquivo novo em `docs/` **requer aprovação do usuário**.
