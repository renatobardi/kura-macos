# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# kura-macos — App macOS SwiftUI

Este repositório contém **exclusivamente o app macOS** do projeto Kura.

**Especificações do produto:** [`renatobardi/kura`](https://github.com/renatobardi/kura) — blueprint, design system, Kura-chan, plano de implementação. Toda decisão de produto está lá.
**Backend API:** [`renatobardi/kura-server`](https://github.com/renatobardi/kura-server) — Elixir/Phoenix + SurrealDB.

---

## Estado atual — Fase 0 em ~99%

> Última atualização: 2026-05-31

Fase 0 completa do ponto de vista de código. Único bloqueio restante: aprovação da conta Apple Developer para ativar o entitlement Sign in with Apple e desabilitar os comentários Firebase. Enquanto isso, `AuthManager.debugSignIn()` (`#if DEBUG`) permite testar o fluxo completo.

### ✅ Implementado

- Projeto Xcode criado: macOS 14+, SwiftUI, Bundle ID `pro.oute.kura`
- Menu bar app: `NSApplicationActivationPolicy.accessory`, `LSUIElement = YES`
- Design tokens: 9 cores em `Assets.xcassets` + `Theme.swift`
- `KeychainHelper.swift` — Security framework, `save()`/`delete()` retornam `Void` (throws sinaliza falha)
- `AuthManager.swift` — `prepareSignInRequest(_:)` gera nonce PKCE e guarda em `pendingNonce`; `completeSignIn(authorization:)` centraliza toda a lógica pós-auth; `restoreSession()` é async com Keychain off main thread
- `LoginView.swift` — delega request para `AuthManager.prepareSignInRequest`, delega completion para `AuthManager.completeSignIn`
- Views básicas: `LoginView`, `DashboardView` (placeholder), `RootView`
- Firebase SDK via SPM: FirebaseAuth + FirebaseAnalytics
- **Remediação de segurança completa:** chave rotacionada, `GoogleService-Info.plist` é template, CI usa GitHub Secrets, histórico limpo
- CI: step de build redundante removido, `set -o pipefail` garante falhas reais quebram o CI
- `README.md` completo criado

### ⏳ Pendente — aguardando Apple Developer Account aprovar

A única pendência para concluir a Fase 0 é a aprovação da conta Apple Developer (Individual / Sole Proprietor).
Quando aprovar, seguir os passos abaixo:

**1. Portal Apple Developer** ([developer.apple.com](https://developer.apple.com))
- Criar App ID com Bundle ID `pro.oute.kura`.
- Habilitar capability **"Sign in with Apple"**.

**2. Xcode**
- Target Kura → Signing & Capabilities → `+` → **Sign in with Apple**.

**3. Código — Descomentar**
- Em `App/AppDelegate.swift`: `FirebaseApp.configure()`.
- Em `Core/Auth/AuthManager.swift`: `import FirebaseAuth` e o bloco Firebase em `completeSignIn(authorization:rawNonce:)` (linhas ~53–57).

**Critério de done da Fase 0:** app abre como menu bar, usuário faz login com Apple ID, CI verde, popover com Liquid Glass no macOS 26, MeshGradient no macOS 15–25, solid no macOS 14.

---

## Stack

| Componente | Tecnologia |
|---|---|
| Plataforma | macOS 14+ |
| UI | SwiftUI (`NSApplicationActivationPolicy.accessory` — menu bar) |
| Design System | Liquid Glass (macOS 26+), MeshGradient (macOS 15+), SymbolEffect (macOS 14+) |
| Auth | Firebase Auth + Sign in with Apple |
| Notificações | **Primário:** WebSocket (Phoenix Channel) + `UserNotifications` locais — sem conta Apple paga. **Futuro:** FCM → APNs por cima, mesmo payload. Ver [`docs/notifications-spec.md`](docs/notifications-spec.md). |
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
├── SESSION.md                      # handoff de estado entre sessões (pode estar atrás do CLAUDE.md — CLAUDE.md é a fonte de verdade)
├── docs/
│   └── notifications-spec.md       # spec do client: WebSocket + notificações locais (handoff do kura-server)
└── Kura/
    ├── Kura.xcodeproj/
    └── Kura/
        ├── App/
        │   ├── KuraApp.swift           # @main, NSApplicationDelegateAdaptor
        │   └── AppDelegate.swift       # menu bar setup, NSStatusItem, NSPopover
        ├── Core/
        │   ├── API/
        │   │   └── KuraEndpoint.swift   # URL do socket (DEBUG localhost / prod wss)
        │   ├── AppState/
        │   │   └── PopoverVisibility.swift # singleton; isShown pausa animações quando oculto
        │   ├── Auth/
        │   │   ├── AuthManager.swift   # ObservableObject, Sign in with Apple
        │   │   └── KeychainHelper.swift
        │   └── Notifications/
        │       ├── NotificationsClient.swift # Phoenix Socket+Channel notifications:<uid>
        │       ├── LocalNotifier.swift  # UserNotifications — entrega local, sem conta paga
        │       └── PushPayload.swift    # model do evento "push"
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
        ├── GoogleService-Info.plist    # AGORA É UM TEMPLATE
        ├── GoogleService-Info.plist.template # template versionado; CI gera o real via GitHub Secrets
        ├── Info.plist                  # LSUIElement=YES, macOS 14+
        ├── Kura.entitlements           # sandbox=NO, network=YES
        └── RootView.swift              # roteador authState → login | dashboard
```

---

## Decisões técnicas

| Decisão | Motivo |
|---------|--------|
| `Settings { EmptyView() }` em `KuraApp` | Apps menu bar puras não têm janelas — a cena `Settings` vazia é obrigatória para o `App` protocol compilar sem `WindowGroup`. |
| `MACOSX_DEPLOYMENT_TARGET = 14.0` | Xcode 26.5 gerou 26.5, corrigido para 14.0 |
| `ENABLE_APP_SANDBOX = NO` | Distribuição via `.dmg` direto, não App Store |
| Colors em `Assets.xcassets` principal | Xcode 16+ auto-gera extensões `Color.kura*` — xcassets separado causaria conflito |
| `PBXFileSystemSynchronizedRootGroup` | Xcode 16+ — arquivos adicionados ao disco são reconhecidos automaticamente |
| Firebase imports comentados | Aguardando Sign in with Apple capability para ativar |
| Team ID `69VJAKBZ5W` | Personal Team — muda para o Team ID correto após aprovação da conta Developer |
| Auth via `prepareSignInRequest` + `completeSignIn` | `prepareSignInRequest(_:)` gera o nonce PKCE, seta `request.nonce`, guarda em `pendingNonce` no singleton (sobrevive ao teardown do popover transient). `completeSignIn(authorization:)` lê `pendingNonce` e faz o sign-in. Para ativar Firebase: descomentar o bloco TODO em `completeSignIn`. |
| `restoreSession()` async | Keychain lido via `Task.detached` fora da main thread. O estado `.unknown` em `RootView` é real — a UI renderiza antes do Keychain responder. |
| `KuraAdaptiveBackground` como view canônica de fundo | Único ponto de decisão por versão: `Color.clear` (macOS 26 — glass do OS visível), `MeshGradient` sutil (macOS 15–25), `kuraBackground` sólido (macOS 14). Inclui guard `accessibilityReduceTransparency`. |
| Glass apenas na camada de navegação | Regra Apple: `glassEffect` em toolbars, botões flutuantes, sheets e popovers — **nunca** em listas, texto ou conteúdo. |
| `KuraGlassContainer` wraps `GlassEffectContainer` | Abstrai o `if #available(macOS 26, *)` das call sites. Glass não pode samplear outro glass — o container coordena composição e habilita transições morfing via `glassEffectID`. |
| `AuthManager.debugSignIn()` atrás de `#if DEBUG` | Entitlement Sign in with Apple requer conta Developer aprovada. O mock usa o mesmo fluxo de Keychain e `authState` — delete os blocos `#if DEBUG` ao ativar Firebase. |
| `@available(macOS 26, *)` guards para glass | macOS 14 é o floor; `glassEffect` e `GlassEffectContainer` só existem no macOS 26. SymbolEffect e MeshGradient têm floors próprios (14 e 15). |
| **Remediação de Chave Exposta** | Uma chave do Firebase foi exposta no histórico do Git, exigindo uma remediação completa para garantir a segurança do projeto. |
| **Uso de `git-filter-repo`** | Ferramenta escolhida para limpar o histórico do Git, removendo permanentemente a chave exposta de todos os commits. |


---

## Credenciais e configurações

| Item | Valor |
|------|-------|
| Bundle ID | `pro.oute.kura` |
| Firebase project | `oute-kura` |
| Firebase Auth callback | `https://oute-kura.firebaseapp.com/__/auth/handler` |
| Apple Developer | Individual / Sole Proprietor (aprovação pendente) |
| Team ID (Personal) | `69VJAKBZ5W` |
| **GitHub Secrets** | `FIREBASE_API_KEY`, `GCM_SENDER_ID`, `FIREBASE_PROJECT_ID`, `FIREBASE_STORAGE_BUCKET`, `GOOGLE_APP_ID` |


---

## Princípios de desenvolvimento

### SwiftUI
- Declarativo em toda UI — UIKit só com necessidade documentada e justificada.
- `NavigationSplitView` para layout sidebar + conteúdo. Sidebar: 260px.
- SF Symbols weight **thin** em todos os ícones.
- `prefers-reduced-motion` respeitado em todas as animações.

### Liquid Glass (macOS 26+)
- `KuraAdaptiveBackground()` é o único fundo de view permitido — nunca `Color.kuraBackground.ignoresSafeArea()` direto.
- Glass pertence à **camada de navegação**: toolbar, botões flutuantes, header, sheets. Nunca em listas, chat ou conteúdo.
- Use `.kuraGlass()` (extensão em `Theme.swift`) para aplicar glass em qualquer View — nunca chame `.glassEffect()` diretamente. Aceita `interactive: Bool` e `cornerRadius: CGFloat`.
- Múltiplos elementos glass sempre dentro de `KuraGlassContainer` (wrapper em `Theme.swift` que abstrai o `#available`). Em macOS <26 renderiza o conteúdo sem wrapper. Glass não pode samplear outro glass.
- `KuraGlass.isActive(reduceTransparency:)` é a fonte de verdade para decidir condicionais de layout (ex.: mostrar/ocultar divider).
- SymbolEffect (macOS 14+) e MeshGradient (macOS 15+) não precisam de guard de disponibilidade separado — `KuraAdaptiveBackground` resolve o branching.

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

**KuraFont scale:** `title` (primaryMedium/18) · `headline` (primaryMedium/15) · `body` (primary/14) · `caption` (primary/12) · `micro` (primary/11). Pesos: W3 (primary), W6 (primaryMedium), W8 (primaryBold).

**KuraSpacing:** `xs:4` · `sm:8` · `md:12` · `lg:16` · `xl:24` · `xxl:32`

**KuraLayout:** `popoverWidth:720` · `popoverHeight:520` · `sidebarWidth:260` · `cornerRadius:10`

---

## Comandos

```bash
# Build (sempre da raiz do repo — nunca usar cd Kura)
xcodebuild build \
  -scheme Kura -project Kura/Kura.xcodeproj \
  -destination 'platform=macOS' \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO

# Testes
xcodebuild test \
  -scheme Kura -project Kura/Kura.xcodeproj \
  -destination 'platform=macOS' \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO

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

### Fase 0 — Fundação — 🟢 99% (aguardando Apple Developer)
- [x] Projeto SwiftUI, macOS 14+, `NSApplicationActivationPolicy.accessory`
- [x] `Info.plist`: `LSUIElement = YES`
- [x] Design tokens: cores, tipografia, spacing em `Assets.xcassets` + `Theme.swift`
- [x] `KeychainHelper.swift` — Security framework
- [x] `AuthManager.swift` — `completeSignIn(authorization:rawNonce:)` + `restoreSession()` async
- [x] `LoginView.swift` — nonce PKCE correto, delega para `AuthManager`
- [x] `DashboardView.swift` (placeholder), `RootView.swift`
- [x] Firebase SDK 12.14.0 via SPM (FirebaseAuth + FirebaseAnalytics)
- [x] GitHub Actions CI com `set -o pipefail`
- [x] **Segurança:** Chave de API rotacionada, restrita e removida do histórico do Git.
- [x] **Documentação:** README.md abrangente criado.
- [x] `KuraAdaptiveBackground` em `Theme.swift` — glass (macOS 26) / MeshGradient (macOS 15–25) / solid (macOS 14) com guard `accessibilityReduceTransparency`
- [x] `popover.appearance = nil` em `AppDelegate` para macOS 26 — desbloqueia chrome glass automático do NSPopover
- [x] Substituir fundos sólidos por `KuraAdaptiveBackground()` em `LoginView`, `DashboardView`, `RootView`
- [x] `GlassEffectContainer` + `.glassEffect(.regular.interactive())` no botão Sign in with Apple (`LoginView`)
- [x] `GlassEffectContainer` + `.glassEffect(.regular.interactive())` no botão sign-out do header (`DashboardView`)
- [x] `.symbolEffect(.pulse.byLayer)` no ícone sparkles da `LoginView`
- [x] `.symbolEffect(.variableColor.iterative)` no ícone sparkles da `DashboardView`, `.symbolEffect(.bounce, value:)` no sign-out
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
- [ ] `GlassEffectContainer` + `.glassEffect()` na toolbar de ações rápidas do chat
- [ ] `.buttonStyle(.glass)` / `.buttonStyle(.glassProminent)` nos botões do composer
- [ ] `.hardScrollEdgeEffect` no `ScrollView` da lista de mensagens
- [ ] `.symbolEffect(.rotate, isActive: isLoading)` no indicador de streaming NDJSON

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
- [~] Push notifications + deep link — client WebSocket + `UserNotifications` locais implementado (`Core/Notifications/` + `Core/API/KuraEndpoint.swift`, wiring em `AppDelegate`). DEBUG conecta com `user_id` cru (server test env); path Firebase ID token pronto-mas-comentado em `NotificationsClient`. **Pendente:** adicionar pacote SwiftPhoenixClient via SPM no Xcode, E2E contra server, e deep-link por `data.type` (precisa das views Fase 4). Spec: [`docs/notifications-spec.md`](docs/notifications-spec.md). APNs entra depois, sem mudar o payload.

### Fase 5 — App Completo — 🔲 não iniciada
- [ ] ⌘K command palette
- [ ] Settings → Account / Privacy / Advanced (Doctor view)
- [ ] Setup wizard + onboarding conduzido por Kura-chan

### Fase 6 — Design, Polish & Ship — 🔲 não iniciada
- [ ] Design system completo (botões, cards, modais, toasts, badges)
- [ ] Kura-chan: Canvas vetorial + 7 estados animados
- [ ] Splash noren (Metal/Canvas, física de tecido)
- [ ] Hanko stamp easter egg
- [ ] `glassEffectID` + `glassEffectTransition(.materialize)` — transições morfing entre elementos glass
- [ ] `glassEffectUnion` para agrupar elementos glass distantes
- [ ] `backgroundExtensionEffect()` no popover — continuidade visual nas bordas
- [ ] `.symbolEffect(.variableColor.iterative.dimInactiveLayers, isActive: hasUnread)` no menu bar icon (badge sem dot)
- [ ] Audit de accessibility: todos os `glassEffect` testados com `Reduce Transparency` ativo
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
