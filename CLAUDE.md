# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# kura-macos — App macOS SwiftUI

Este repositório contém **exclusivamente o app macOS** do projeto Kura.

**Especificações do produto:** [`renatobardi/kura`](https://github.com/renatobardi/kura) — blueprint, design system, Kura-chan, plano de implementação. Toda decisão de produto está lá.
**Backend API:** [`renatobardi/kura-server`](https://github.com/renatobardi/kura-server) — Elixir/Phoenix + SurrealDB.

---

## Estado atual — Fase 0 em 90%

> Última atualização: 2026-05-30

### ✅ Implementado (commit `feat(foundation): implement phase 0` — `main`)

- Projeto Xcode criado: macOS 14+, SwiftUI, Bundle ID `pro.oute.kura`
- Menu bar app: `NSApplicationActivationPolicy.accessory`, `LSUIElement = YES`
- Design tokens: 9 cores em `Assets.xcassets` + `Theme.swift` (KuraFont, KuraSpacing, KuraLayout)
- `KeychainHelper.swift` — Security framework, nunca UserDefaults
- `AuthManager.swift` — Sign in with Apple + SHA256 nonce (Firebase stub comentado aguardando capability)
- `LoginView.swift`, `DashboardView.swift` (placeholder), `RootView.swift`
- Firebase SDK 12.14.0 via SPM: FirebaseAuth + FirebaseAnalytics
- `GoogleService-Info.plist` no projeto (Firebase project: `oute-kura`)
- `.github/workflows/ci.yml` — GitHub Actions build + test
- Build: **0 errors, 0 warnings**

### ⏳ Pendente — aguardando Apple Developer Account aprovar (~2 dias)

A conta Apple Developer foi criada como **Individual / Sole Proprietor** e está em aprovação.
Quando aprovar, fazer em ordem:

**1. Portal Apple Developer** ([developer.apple.com](https://developer.apple.com))
- Certificates, Identifiers & Profiles → criar App ID com Bundle ID `pro.oute.kura`
- Habilitar capability **"Sign in with Apple"** no App ID

**2. Firebase Console** ([console.firebase.google.com](https://console.firebase.google.com) → projeto `oute-kura`)
- Authentication → Sign-in method → Apple → adicionar Return URL:
  `https://oute-kura.firebaseapp.com/__/auth/handler`

**3. Xcode**
- Target Kura → Signing & Capabilities → `+` → **Sign in with Apple**
- Isso atualiza `Kura/Kura/Kura.entitlements` automaticamente

**4. Código — descomentar em `App/AppDelegate.swift`:**
```swift
import FirebaseCore          // adicionar import
// FirebaseApp.configure()   // remover //
```
**E em `Core/Auth/AuthManager.swift`:**
```swift
// import FirebaseAuth       // remover //
```
E descomentar o bloco Firebase credential em `authorizationController(didCompleteWithAuthorization:)` (linhas ~95-99)

**Critério de done da Fase 0:** app abre como menu bar, usuário faz login com Apple ID, CI verde.

---

## Stack

| Componente | Tecnologia |
|---|---|
| Plataforma | macOS 14+ |
| UI | SwiftUI (`NSApplicationActivationPolicy.accessory` — menu bar) |
| Auth | Firebase Auth + Sign in with Apple |
| Notificações | FCM → APNs |
| Keychain | Security framework — tokens sempre aqui, nunca UserDefaults |
| Rede | Phoenix Channels (WebSocket) + URLSession (REST) |
| Auto-update | Sparkle (delta updates, background download) |
| Distribuição | .dmg assinado + notarização Apple |

---

## Estrutura do projeto (atual)

```
kura-macos/
├── .github/workflows/ci.yml
├── CLAUDE.md
└── Kura/
    ├── Kura.xcodeproj/
    └── Kura/
        ├── App/
        │   ├── KuraApp.swift           # @main, NSApplicationDelegateAdaptor
        │   └── AppDelegate.swift       # menu bar setup, NSStatusItem, NSPopover
        ├── Core/
        │   └── Auth/
        │       ├── AuthManager.swift   # ObservableObject, Sign in with Apple
        │       └── KeychainHelper.swift
        ├── Design/
        │   └── Theme/
        │       └── Theme.swift         # KuraFont, KuraSpacing, KuraLayout
        ├── Features/
        │   ├── Auth/
        │   │   └── LoginView.swift
        │   ├── Chat/                   # vazio — Fase 1
        │   ├── Dashboard/
        │   │   └── DashboardView.swift # placeholder pós-login
        │   ├── Inbox/                  # vazio — Fase 4
        │   ├── Search/                 # vazio — Fase 5
        │   └── Settings/              # vazio — Fase 1
        ├── Assets.xcassets/            # 9 color tokens + AppIcon
        ├── GoogleService-Info.plist
        ├── Info.plist                  # LSUIElement=YES, macOS 14+
        ├── Kura.entitlements           # sandbox=NO, network=YES
        └── RootView.swift              # roteador authState → login | dashboard
```

---

## Decisões técnicas desta sessão

| Decisão | Motivo |
|---------|--------|
| `MACOSX_DEPLOYMENT_TARGET = 14.0` | Xcode 26.5 gerou 26.5, corrigido para 14.0 |
| `ENABLE_APP_SANDBOX = NO` | Distribuição via `.dmg` direto, não App Store |
| Colors em `Assets.xcassets` principal | Xcode 16+ auto-gera extensões `Color.kura*` — xcassets separado causaria conflito |
| `PBXFileSystemSynchronizedRootGroup` | Xcode 16+ — arquivos adicionados ao disco são reconhecidos automaticamente |
| Firebase imports comentados | Aguardando Sign in with Apple capability para ativar |
| Team ID `69VJAKBZ5W` | Personal Team — muda para o Team ID correto após aprovação da conta Developer |

---

## Credenciais e configurações

| Item | Valor |
|------|-------|
| Bundle ID | `pro.oute.kura` |
| Firebase project | `oute-kura` |
| Firebase Auth callback | `https://oute-kura.firebaseapp.com/__/auth/handler` |
| Apple Developer | Individual / Sole Proprietor (aprovação pendente) |
| Team ID (Personal) | `69VJAKBZ5W` |

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
Tokens em `Assets.xcassets` — nunca hardcode valores de cor:

| Token | Valor | Papel |
|---|---|---|
| `kuraAccent` | `#3730A3` | Índigo/藍 — cor principal |
| `kuraAccentHover` | `#4338CA` | Hover do accent |
| `kuraBackground` | `#212121` | Fundo dark |
| `kuraSidebar` | `#171717` | Sidebar dark |
| `kuraHanko` | `#9B1C1C` | Seal 蔵 — único momento quente |
| `kuraText` | `#ECECEC` | Texto primário |
| `kuraTextMuted` | `#6B7280` | Texto secundário |
| `kuraDivider` | `#2D2D2D` | Separadores |
| `kuraSurface` | `#2A2A2A` | Cards/surfaces |

Hiragino Sans como tipografia primária (não fallback) em todos os textos.

---

## Comandos

```bash
# Build
cd Kura && xcodebuild build \
  -scheme Kura -project Kura.xcodeproj \
  -destination 'platform=macOS' \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO

# Testes
cd Kura && xcodebuild test \
  -scheme Kura -project Kura.xcodeproj \
  -destination 'platform=macOS' \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO

# Formatar Swift
swift-format --in-place Kura/Kura/**/*.swift
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
| 8 | `trivy-scanner` | PreToolUse | Bash | Bloqueia deploy com CRITICAL/HIGH/MEDIUM; avisa em LOW |
| 9 | `sonarcloud` | PreToolUse | Bash | Quality Gate antes de `gh pr create` |
| 10 | `pr-standards` | PreToolUse | Bash | Valida título e body antes de `gh pr create` |
| 11 | `code-review-gate` | PreToolUse | Bash | Code review via Claude antes de `gh pr merge` |

> Se um hook bloquear, corrija o problema — não tente contorná-lo.

---

## Plano de implementação

### Fase 0 — Fundação — 🟡 90% (aguardando Apple Developer)
- [x] Projeto SwiftUI, macOS 14+, `NSApplicationActivationPolicy.accessory`
- [x] `Info.plist`: `LSUIElement = YES`
- [x] Design tokens: cores, tipografia, spacing em `Assets.xcassets` + `Theme.swift`
- [x] `KeychainHelper.swift` — Security framework
- [x] `AuthManager.swift` — Sign in with Apple + nonce
- [x] `LoginView.swift`, `DashboardView.swift` (placeholder), `RootView.swift`
- [x] Firebase SDK 12.14.0 via SPM (FirebaseAuth + FirebaseAnalytics)
- [x] GitHub Actions CI
- [ ] Registrar Bundle ID no Apple Developer Portal
- [ ] Capability "Sign in with Apple" no App ID
- [ ] Descomentar FirebaseApp.configure() + FirebaseAuth imports

### Fase 1 — Chat — 🔲 não iniciada
- [ ] Sidebar com lista de chats (`NavigationSplitView`, 260px)
- [ ] View de chat: composer, mensagens, streaming NDJSON
- [ ] Chat anônimo (`/anon`)
- [ ] Upload de arquivo (drag-and-drop)
- [ ] Título editável + lock/unlock
- [ ] Settings → AI & Models: configurar providers BYOS
- [ ] `Core/API/ChannelClient.swift` — Phoenix Channels

**Critério de done:** conversa fluindo, streaming visível, anexo sendo processado.

### Fase 2 — Vault — 🔲 não iniciada
- [ ] View do vault: árvore de páginas, busca, página individual
- [ ] Grafo de conhecimento (visualização)
- [ ] Ask/RAG: input de query, resposta com citações linkáveis
- [ ] Lapidação via chat

### Fase 3 — Collectors — 🔲 não iniciada
- [ ] Settings → Connections: Google OAuth (Gmail + Drive)
- [ ] Settings → Connections: RSS feed
- [ ] `Collectors.LocalWatcher`: FSEvents → Phoenix Channel
- [ ] Indicador no menu bar: collector ativo / erro

### Fase 4 — Outputs & Inbox — 🔲 não iniciada
- [ ] Dashboard diário (SwiftUI nativo)
- [ ] Player de áudio do briefing
- [ ] Inbox view + interação conversacional
- [ ] Badge no menu bar
- [ ] Push notifications + deep link

### Fase 5 — App Completo — 🔲 não iniciada
- [ ] ⌘K command palette
- [ ] Settings → Account / Privacy / Advanced (Doctor view)
- [ ] Setup wizard + onboarding conduzido por Kura-chan

### Fase 6 — Design, Polish & Ship — 🔲 não iniciada
- [ ] Design system completo (botões, cards, modais, toasts, badges)
- [ ] Kura-chan: Canvas vetorial + 7 estados animados
- [ ] Splash noren (Metal/Canvas, física de tecido)
- [ ] Hanko stamp easter egg
- [ ] `.dmg` assinado + notarização Apple
- [ ] Sparkle auto-update
- [ ] XCUITest nos fluxos críticos

### Fora do MVP — não implementar sem instrução explícita
- iOS / iPadOS app
- Microsoft OAuth (Outlook, OneDrive)
- iCloud Mail / Drive
- Vault por Space / Project
- Egg universe pop culture completo
- Weekly digest, entity profiles, deep dive áudio

---

## Workflow

### Branches
```
main           — produção (.dmg + Sparkle), protegida
develop        — integração
feat/<slug>    — nova feature
fix/<slug>     — correção de bug
hotfix/<slug>  — correção urgente em produção
chore/<slug>   — infra, deps, config
docs/<slug>    — documentação
refactor/<slug> | perf/<slug> | test/<slug> | ci/<slug>
```

### Commits (Conventional Commits)
```
type(scope): descrição em inglês, imperativo, ≤72 chars
```
- Descrição começa com **minúscula**, não termina com **ponto**
- Body separado do subject por **linha em branco**

### Pull Requests
```
## What
## Why
## How
```
