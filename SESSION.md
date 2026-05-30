# SESSION.md — Estado do projeto para retomada

> Atualizado em: 2026-05-30
> Última sessão: Fase 0 — Fundação

---

## 🔴 Status atual: Fase 0 — 90% concluída

### O que foi feito nessa sessão:

- ✅ Projeto Xcode criado (macOS 14+, SwiftUI, `pro.oute.kura`)
- ✅ Estrutura de pastas: `App/`, `Core/`, `Design/`, `Features/`
- ✅ Menu bar app: `NSApplicationActivationPolicy.accessory`, `LSUIElement = YES`
- ✅ Design tokens: 9 cores no `Assets.xcassets` + `Theme.swift` (KuraFont, KuraSpacing, KuraLayout)
- ✅ `KeychainHelper.swift` — Security framework, nunca UserDefaults
- ✅ `AuthManager.swift` — Sign in with Apple + SHA256 nonce (Firebase stub comentado)
- ✅ `LoginView.swift` — Sign in with Apple button
- ✅ `DashboardView.swift` — placeholder pós-login
- ✅ `RootView.swift` — roteador login ↔ dashboard
- ✅ Firebase SDK 12.14.0 via SPM (FirebaseAuth + FirebaseAnalytics)
- ✅ `GoogleService-Info.plist` no projeto (Bundle ID: `pro.oute.kura`, projeto: `oute-kura`)
- ✅ `.github/workflows/ci.yml` — GitHub Actions build + test
- ✅ Build: 0 errors, 0 warnings
- ✅ Commit `feat(foundation): implement phase 0` na `main` — local e remoto alinhados

---

## ⏳ Fase 0 — Pendente (aguardando Apple Developer aprovar ~2 dias)

A conta Apple Developer foi criada como **Individual / Sole Proprietor** e está em aprovação.
Quando aprovar, fazer estes 4 passos em ordem:

### Passo 1 — Portal Apple Developer
- Acessa [developer.apple.com](https://developer.apple.com) → Certificates, Identifiers & Profiles
- Cria um **App ID**: Bundle ID = `pro.oute.kura`
- Habilita a capability **"Sign in with Apple"** nesse App ID

### Passo 2 — Firebase
- Acessa o [Firebase Console](https://console.firebase.google.com) → projeto `oute-kura`
- Authentication → Sign-in method → Apple → colar em "Return URLs":
  ```
  https://oute-kura.firebaseapp.com/__/auth/handler
  ```

### Passo 3 — Xcode
- Abre `Kura/Kura.xcodeproj`
- Clica no target **Kura** → aba **Signing & Capabilities**
- Clica em **`+` Capability** → adiciona **"Sign in with Apple"**
- Isso vai atualizar o `Kura.entitlements` automaticamente

### Passo 4 — Código (descomentar)
Em `Kura/Kura/App/AppDelegate.swift`, linha ~17:
```swift
// FirebaseApp.configure()
```
→ Remove o `//` e adiciona `import FirebaseCore` no topo

Em `Kura/Kura/Core/Auth/AuthManager.swift`, linha ~5:
```swift
// import FirebaseAuth
```
→ Remove o `//`

E descomenta o bloco de Firebase credential no método `authorizationController(didCompleteWithAuthorization:)` (~linhas 95-99)

---

## 📁 Estrutura do projeto

```
kura-macos/
├── .github/workflows/ci.yml
├── Kura/
│   ├── Kura.xcodeproj/
│   └── Kura/
│       ├── App/
│       │   ├── KuraApp.swift          ← @main, NSApplicationDelegateAdaptor
│       │   └── AppDelegate.swift      ← menu bar setup, NSStatusItem, NSPopover
│       ├── Core/
│       │   └── Auth/
│       │       ├── AuthManager.swift  ← ObservableObject, Sign in with Apple
│       │       └── KeychainHelper.swift ← Security framework wrapper
│       ├── Design/
│       │   └── Theme/
│       │       └── Theme.swift        ← KuraFont, KuraSpacing, KuraLayout
│       ├── Features/
│       │   ├── Auth/
│       │   │   └── LoginView.swift
│       │   └── Dashboard/
│       │       └── DashboardView.swift ← placeholder fase 0
│       ├── Assets.xcassets/           ← 9 color tokens + AppIcon
│       ├── GoogleService-Info.plist
│       ├── Info.plist                 ← LSUIElement=YES, macOS 14+
│       ├── Kura.entitlements          ← sandbox=NO, network=YES
│       └── RootView.swift             ← roteador auth state
└── CLAUDE.md
```

---

## 🎨 Design tokens implementados

| Token | Hex | Papel |
|-------|-----|-------|
| `kuraBackground` | `#212121` | Fundo principal |
| `kuraSidebar` | `#171717` | Sidebar |
| `kuraAccent` | `#3730A3` | Índigo — cor principal |
| `kuraAccentHover` | `#4338CA` | Hover do accent |
| `kuraHanko` | `#9B1C1C` | Seal 蔵 |
| `kuraText` | `#ECECEC` | Texto primário |
| `kuraTextMuted` | `#6B7280` | Texto secundário |
| `kuraDivider` | `#2D2D2D` | Separadores |
| `kuraSurface` | `#2A2A2A` | Cards/surfaces |

---

## 🚀 Próxima fase: Fase 1 — Chat

**Usar modelo: Qwen3-Coder** (Sonnet é caro para fases 1+)

### O que a Fase 1 precisa construir:
- Sidebar com lista de chats (`NavigationSplitView`, sidebar 260px)
- View de chat: composer, mensagens, streaming NDJSON
- Chat anônimo (`/anon`)
- Upload de arquivo (drag-and-drop)
- Título editável + lock/unlock
- Settings → AI & Models: configurar providers BYOS
- Integração com Phoenix Channels (`Core/API/ChannelClient.swift`)

**Critério de done:** conversa fluindo, streaming visível, anexo sendo processado.

---

## 🔑 Credenciais e configs importantes

| Item | Valor |
|------|-------|
| Bundle ID | `pro.oute.kura` |
| Firebase project | `oute-kura` |
| Firebase Auth callback | `https://oute-kura.firebaseapp.com/__/auth/handler` |
| Apple Developer | Individual / Sole Proprietor (aprovação pendente) |
| Team ID | `69VJAKBZ5W` (Personal Team — muda após aprovação) |
| Repo | `renatobardi/kura-macos` |
| Backend | `renatobardi/kura-server` (Elixir/Phoenix + SurrealDB) |

---

## ⚠️ Decisões técnicas importantes desta sessão

1. **`MACOSX_DEPLOYMENT_TARGET = 14.0`** — Xcode 26.5 gerou 26.5, corrigimos para 14.0
2. **`ENABLE_APP_SANDBOX = NO`** — distribuição via `.dmg` direto, não App Store
3. **Colors no `Assets.xcassets` principal** — não em xcassets separado (Xcode auto-gera as extensões)
4. **`PBXFileSystemSynchronizedRootGroup`** — Xcode 16+ sincroniza arquivos automaticamente, não precisa adicionar manualmente ao `.xcodeproj`
5. **Firebase imports comentados** — aguardando Sign in with Apple capability para ativar
