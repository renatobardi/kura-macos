# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# kura-macos — App macOS SwiftUI

Este repositório contém **exclusivamente o app macOS** do projeto Kura.

**Especificações do produto:** [`renatobardi/kura`](https://github.com/renatobardi/kura) — blueprint, design system, Kura-chan, plano de implementação. Toda decisão de produto está lá.
**Backend API:** [`renatobardi/kura-server`](https://github.com/renatobardi/kura-server) — Elixir/Phoenix + SurrealDB.

---

## Stack

| Componente | Tecnologia |
|---|---|
| Plataforma | macOS 13+ |
| UI | SwiftUI (`NSApplicationActivationPolicy.accessory` — menu bar) |
| Auth | Firebase Auth + Sign in with Apple |
| Notificações | FCM → APNs |
| Keychain | Security framework — tokens sempre aqui, nunca UserDefaults |
| Rede | Phoenix Channels (WebSocket) + URLSession (REST) |
| Auto-update | Sparkle (delta updates, background download) |
| Distribuição | .dmg assinado + notarização Apple |

---

## Estado atual

Pré-implementação. Contém apenas hooks Claude Code e documentação.
**Ainda não existem:** projeto Xcode, `Sources/`, `Tests/`.
Primeira tarefa: criar projeto SwiftUI no Xcode (macOS target, `LSUIElement = YES` no Info.plist para menu bar app sem dock icon).

---

## Estrutura do projeto (target)

```
KuraApp/
├── App/
│   ├── KuraApp.swift          # Entry point, menu bar setup
│   └── AppDelegate.swift
├── Features/
│   ├── Auth/                  # Sign in with Apple + Firebase flow
│   ├── Chat/                  # Chat persistente + anônimo + streaming NDJSON
│   ├── Vault/                 # Ask/RAG + lapidação via chat
│   ├── Dashboard/             # Daily briefing visual + player de áudio
│   ├── Inbox/                 # Centro de comando assíncrono
│   ├── Search/                # ⌘K command palette
│   └── Settings/              # AI, Connections, Privacy, etc.
├── Core/
│   ├── API/                   # Phoenix Channels client + URLSession REST
│   ├── Auth/                  # Firebase + Sign in with Apple helpers
│   ├── Models/                # Tipos compartilhados (Codable structs)
│   └── Notifications/         # FCM registration + APNs handling
└── Design/
    ├── Theme/                 # Color tokens, tipografia, spacing
    ├── Components/            # Botões, cards, toasts, modais, badges
    ├── KuraChan/              # Personagem + estados + animações
    └── Splash/                # Noren animation (primeira abertura do dia)
```

---

## Princípios de desenvolvimento

### SwiftUI
- Declarativo em toda UI — UIKit só com necessidade documentada e justificada.
- `NavigationSplitView` para layout sidebar + conteúdo. Sidebar: 260px.
- SF Symbols weight **thin** em todos os ícones.
- `prefers-reduced-motion` respeitado em todas as animações.

### Segurança — Keychain obrigatório
- Tokens, credenciais e dados sensíveis **sempre** no Keychain via Security framework.
- **Nunca** use `UserDefaults` para tokens, API keys ou dados de autenticação.
- O hook `swift-keychain-enforcer` bloqueia `UserDefaults.standard.set` com chaves sensíveis.

### Arquitetura de feature
- Cada feature em `Features/<Nome>/`: View + ViewModel + Model.
- Toda comunicação com a API em `Core/API/` — nunca URLSession direto nas Views.
- Phoenix Channels encapsulados em `Core/API/ChannelClient.swift`.

### Design System
Tokens definidos em `Design/Theme/` — nunca hardcode valores de cor:

| Token | Valor | Papel |
|---|---|---|
| `accent` | `#3730A3` | Índigo/藍 — cor principal |
| `accentHover` | `#4338CA` | Hover do accent |
| `background` | `#212121` | Fundo dark |
| `sidebar` | `#171717` | Sidebar dark |
| `hanko` | `#9B1C1C` | Seal 蔵 — único momento quente |
| `text` | `#ECECEC` | Texto primário |

Hiragino Sans como tipografia primária (não fallback) em todos os textos.

---

## Comandos

```bash
# Testes (após criação do projeto Xcode)
xcodebuild test -scheme Kura -destination 'platform=macOS'

# Build
xcodebuild build -scheme Kura -destination 'platform=macOS'

# Formatar Swift (o hook swift-format faz automaticamente no Edit)
swift-format --in-place Sources/**/*.swift

# Debugar hook isoladamente
python3 .claude/hooks/<hook>.py < event.json
```

---

## Hooks ativos

Todos em `.claude/hooks/`. Rodam automaticamente via `.claude/settings.json`.

| # | Hook | Evento | Dispara em | Ação |
|---|---|---|---|---|
| 1 | `secret-scanner` | PreToolUse | Write \| Edit | Bloqueia API keys e credenciais no código |
| 2 | `env-file-protection` | PreToolUse | Write \| Edit \| Bash | Protege arquivos sensíveis de config |
| 3 | `swift-keychain-enforcer` | PreToolUse | Write \| Edit | Bloqueia `UserDefaults` para dados sensíveis |
| 4 | `swift-format` | PostToolUse | Edit | Formata `.swift` in-place |
| 5 | `branch-taxonomy` | PreToolUse | Bash | Bloqueia `git checkout -b` fora do padrão |
| 6 | `commit-message` | PreToolUse | Bash | Enforce Conventional Commits |
| 7 | `swift-commit-gate` | PreToolUse | Bash | Bloqueia commit se `xcodebuild test` falhar |
| 8 | `trivy-scanner` | PreToolUse | Bash | Scan de segurança antes de push/deploy |
| 9 | `sonarcloud` | PreToolUse | Bash | Quality Gate antes de `gh pr create` |
| 10 | `pr-standards` | PreToolUse | Bash | Valida título e body antes de `gh pr create` |
| 11 | `code-review-gate` | PreToolUse | Bash | Code review via Claude antes de `gh pr merge` |

> Se um hook bloquear, corrija o problema — não tente contorná-lo.

---

## Plano de implementação — App macOS

Plano completo em [`KURA-MVP-PLAN.md`](https://github.com/renatobardi/kura/blob/main/KURA-MVP-PLAN.md). Abaixo: tarefas do app macOS por fase.

### Fase 0 — Fundação
- [ ] Projeto SwiftUI novo, target macOS, `NSApplicationActivationPolicy.accessory` (menu bar, sem dock icon)
- [ ] `Info.plist`: `LSUIElement = YES`
- [ ] Design tokens: cores, tipografia, SF Symbols thin em `Design/Theme/`
- [ ] Sign in with Apple → troca token Firebase → armazena no Keychain
- [ ] Tela pós-login (placeholder)
- [ ] GitHub Actions com macOS runner: build + testes

**Critério de done:** app abre como menu bar, usuário faz login com Apple ID, CI verde.

### Fase 1 — Chat
- [ ] Sidebar com lista de chats
- [ ] View de chat: composer, mensagens, streaming NDJSON
- [ ] Chat anônimo (`/anon`)
- [ ] Upload de arquivo (drag-and-drop)
- [ ] Título editável + lock/unlock
- [ ] Settings → AI & Models: configurar providers BYOS

**Critério de done:** conversa fluindo, streaming visível, anexo sendo processado.

### Fase 2 — Vault
- [ ] View do vault: árvore de páginas, busca, página individual
- [ ] Grafo de conhecimento (visualização)
- [ ] Ask/RAG: input de query, resposta com citações linkáveis
- [ ] Lapidação via chat: "ajusta isso na página X" → LLM aplica

**Critério de done:** ingerir, perguntar, ver resposta com citação.

### Fase 3 — Collectors
- [ ] Settings → Connections: conectar Google OAuth (Gmail + Drive)
- [ ] Settings → Connections: adicionar RSS feed
- [ ] `Collectors.LocalWatcher`: FSEvents detecta mudanças → envia ao backend via Phoenix Channel
- [ ] Indicador no menu bar: collector ativo / erro
- [ ] Exclusão por fonte: configuração conversacional

### Fase 4 — Outputs & Inbox
- [ ] Home view: dashboard diário (visual, SwiftUI nativo)
- [ ] Player de áudio do briefing
- [ ] Inbox view: lista de items pendentes, interação conversacional
- [ ] Badge no menu bar quando há items no Inbox
- [ ] Push notifications recebidas + deep link para item

**Critério de done:** abre app de manhã, vê dashboard, ouve briefing, trata Inbox.

### Fase 5 — App Completo
- [ ] ⌘K command palette: busca + ações, resultados agrupados (Vaults / Chats / Files / Actions)
- [ ] Settings → Account: dashboard de custo por período/tipo/total
- [ ] Settings → Privacy: gerenciar regras de exclusão
- [ ] Settings → Advanced: Doctor view (Kura-chan preocupada se componente vermelho)
- [ ] Setup wizard completo conduzido por Kura-chan
- [ ] Onboarding lúdico: LLM pergunta interesses e constrói ontologia
- [ ] Folder sync: `iCloud Drive/Kura/Projects` + `Spaces/`

### Fase 6 — Design, Polish & Ship
- [ ] Design system completo: todos os tokens implementados como Color assets
- [ ] Componentes SwiftUI: botões (primary/ghost/danger), cards, modais, toasts, tooltips, badges
- [ ] Kura-chan: modelo vetorial (SwiftUI Canvas) + estados (pensando, trabalhando, feliz, dormindo, apologética, relaxando, esperando)
- [ ] Splash screen noren (Metal/Canvas, física de tecido, só na 1ª abertura do dia)
- [ ] Easter egg MVP: hanko stamp (save / promoção ao vault)
- [ ] Build `.dmg` assinado (Apple Developer certificate) + notarização
- [ ] Sparkle integrado (servidor de updates via GitHub Releases)
- [ ] XCUITest nos fluxos críticos

**Critério de done:** .dmg instalável, auto-update funcionando, app parece produto premium.

### Fora do MVP — não implementar sem instrução explícita
- iOS / iPadOS app
- Microsoft OAuth (Outlook, OneDrive)
- iCloud Mail / Drive
- Vault por Space / Project
- Egg universe pop culture completo (só hanko no MVP)
- Weekly digest, entity profiles, deep dive áudio

---

## Workflow

### Branches
```
main          — produção (.dmg + Sparkle), protegida
develop       — integração
feat/<slug>   — nova feature
fix/<slug>    — correção de bug
chore/<slug>  — infra, deps, config
docs/<slug>   — documentação
refactor/<slug>
perf/<slug>
test/<slug>
ci/<slug>
```

### Commits (Conventional Commits)
```
type(scope): descrição em inglês, imperativo, ≤72 chars

Tipos: feat, fix, docs, style, refactor, perf, test, chore, ci, revert
```

### Pull Requests
- Título: `type(scope): descrição`
- Body obrigatório:
  ```
  ## What
  ## Why
  ## How
  ```
- O hook `pr-standards` valida antes de `gh pr create`.
- O hook `code-review-gate` valida antes de `gh pr merge`.
