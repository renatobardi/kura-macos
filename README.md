# Kura for macOS

[![CI](https://github.com/renatobardi/kura-macos/actions/workflows/ci.yml/badge.svg)](https://github.com/renatobardi/kura-macos/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-indigo.svg)](https://opensource.org/licenses/MIT)

> A native, SwiftUI-based menu bar application for the Kura platform.

This repository contains the source code for the Kura macOS client. It is built to be a lightweight, secure, and intuitive interface for interacting with the Kura ecosystem directly from your menu bar.

_Note: This project is currently in its foundational phase, awaiting Apple Developer account approval to enable Sign in with Apple and Firebase authentication._

---

## ✨ Features

- **Menu Bar Native:** Lives in your macOS menu bar for quick and easy access.
- **Liquid Glass UI:** Adopts Apple's macOS 26 Liquid Glass design language — transparent popover chrome on macOS 26+, animated MeshGradient on macOS 15–25, and a clean dark solid on macOS 14.
- **Secure Authentication:** Sign in with Apple with PKCE nonce, credentials stored exclusively in the macOS Keychain.
- **Accessibility First:** Respects both Reduce Transparency and Reduce Motion system settings throughout.
- **SwiftUI Native:** Built entirely with modern SwiftUI for a responsive and native user experience.
- **Secure by Design:** Automated hooks prevent secrets from being committed and enforce secure coding practices.
- **CI/CD Ready:** GitHub Actions pipeline with `set -o pipefail` — real failures break the build.

## 🚀 Getting Started

Follow these instructions to get a copy of the project up and running on your local machine for development.

### Prerequisites

- **macOS:** 14.0 or later
- **Xcode:** 26.0 or later _(required — `glassEffect` and other macOS 26 APIs are only available in the Xcode 26 SDK)_
- **Homebrew:** (for development tools)
  ```sh
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  ```

### Building the Project

1. **Clone the repository:**
   ```sh
   git clone https://github.com/renatobardi/kura-macos.git
   cd kura-macos
   ```

2. **Set up Firebase Credentials:**
   This project requires a `GoogleService-Info.plist` file to connect to Firebase. This file is not checked into Git for security reasons. A template is provided at `Kura/Kura/GoogleService-Info.plist.template`.
   - Go to the [Firebase Console](https://console.firebase.google.com/) and select the `oute-kura` project.
   - Navigate to **Project Settings > General**, select the Kura macOS app, and download `GoogleService-Info.plist`.
   - Place it at `Kura/Kura/GoogleService-Info.plist`.

3. **Resolve Dependencies:**
   Open the project in Xcode and it will automatically resolve SPM dependencies. Or run:
   ```sh
   cd Kura && xcodebuild -resolvePackageDependencies -scheme Kura -project Kura.xcodeproj
   ```

4. **Build:**
   ```sh
   xcodebuild build \
     -scheme Kura -project Kura/Kura.xcodeproj \
     -destination 'platform=macOS' \
     CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO
   ```
   Or open `Kura/Kura.xcodeproj` in Xcode and press `Cmd+B`.

## 🛠️ Tech Stack

| Component | Technology |
| :--- | :--- |
| **Platform** | macOS 14+ |
| **UI** | SwiftUI (`NSApplicationActivationPolicy.accessory` — menu bar) |
| **Design System** | Liquid Glass (macOS 26+), MeshGradient (macOS 15+), SymbolEffect (macOS 14+) |
| **Authentication** | Firebase Auth + Sign in with Apple (PKCE nonce) |
| **Secure Storage** | macOS Keychain via Security framework |
| **CI/CD** | GitHub Actions |
| **Dependencies** | Swift Package Manager |

## 📂 Project Structure

```
kura-macos/
├── .github/workflows/ci.yml    # GitHub Actions CI/CD pipeline
├── .claude/                    # Claude Code hooks (secrets, commit standards, etc.)
├── Kura/
│   ├── Kura.xcodeproj/
│   └── Kura/
│       ├── App/                # Entry point (KuraApp, AppDelegate + NSPopoverDelegate)
│       ├── Core/
│       │   ├── AppState/       # PopoverVisibility — drives animation pausing
│       │   └── Auth/           # AuthManager (PKCE, Keychain), KeychainHelper
│       ├── Design/Theme/       # Theme.swift: KuraFont, KuraSpacing, KuraLayout,
│       │                       # KuraAdaptiveBackground, KuraGlass modifier
│       ├── Features/
│       │   ├── Auth/           # LoginView (Sign in with Apple)
│       │   └── Dashboard/      # DashboardView (placeholder — Phase 4)
│       └── Assets.xcassets/    # 9 color design tokens + AppIcon
└── README.md
```

## 🤝 Contributing

1. **Branch naming:** Use prefixes like `feat/`, `fix/`, `chore/`, `docs/` (e.g. `feat/chat-sidebar`).
2. **Commits:** Follow [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) — description lowercase, no trailing period, ≤72 chars.
3. **Glass guidelines:** `glassEffect` belongs on the navigation layer only (toolbar, buttons, sheets). Never on content (lists, text, media). Use `KuraAdaptiveBackground()` for all view backgrounds — never `Color.kuraBackground.ignoresSafeArea()` directly.

## 📜 License

Distributed under the MIT License. See `LICENSE` for more information.
