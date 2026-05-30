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
