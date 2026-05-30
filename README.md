# Kura for macOS

[![CI](https://github.com/renatobardi/kura-macos/actions/workflows/ci.yml/badge.svg)](https://github.com/renatobardi/kura-macos/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-indigo.svg)](https://opensource.org/licenses/MIT)

> A native, SwiftUI-based menu bar application for the Kura platform.

This repository contains the source code for the Kura macOS client. It is built to be a lightweight, secure, and intuitive interface for interacting with the Kura ecosystem directly from your menu bar.

_Note: This project is currently in its foundational phase, awaiting Apple Developer account approval to enable all authentication features._

---

## ✨ Features

- **Menu Bar Native:** Lives in your macOS menu bar for quick and easy access.
- **Secure Authentication:** Uses Sign in with Apple and stores all credentials securely in the macOS Keychain.
- **SwiftUI Native:** Built entirely with modern SwiftUI for a responsive and native user experience.
- **Secure by Design:** Includes automated hooks to prevent secrets from being committed and enforces secure coding practices.
- **CI/CD Ready:** Integrated with GitHub Actions for automated builds and tests.

## 🚀 Getting Started

Follow these instructions to get a copy of the project up and running on your local machine for development and testing purposes.

### Prerequisites

- **macOS:** 14.0 or later
- **Xcode:** 16.0 or later
- **Homebrew:** (for development tools)
  ```sh
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  ```

### Building the Project

1.  **Clone the repository:**
    ```sh
    git clone https://github.com/renatobardi/kura-macos.git
    cd kura-macos
    ```

2.  **Set up Firebase Credentials (Crucial):**
    This project requires a `GoogleService-Info.plist` file to connect to Firebase services. This file is not checked into Git for security reasons.
    - Go to the [Firebase Console](https://console.firebase.google.com/) and select the `oute-kura` project.
    - Navigate to **Project Settings** > **General**.
    - In the "Your apps" section, select the Kura macOS app and download the `GoogleService-Info.plist` file.
    - Place the downloaded file into the `Kura/Kura/` directory.

3.  **Resolve Dependencies:**
    Open the project in Xcode, and it will automatically resolve the Swift Package Manager dependencies. Alternatively, you can run:
    ```sh
    cd Kura && xcodebuild -resolvePackageDependencies -scheme Kura -project Kura.xcodeproj
    ```

4.  **Run the App:**
    Open `Kura/Kura.xcodeproj` in Xcode and press `Cmd+R` to build and run the application.

## 🛠️ Tech Stack

| Component | Technology / Library |
| :--- | :--- |
| **Platform** | macOS 14+ |
| **UI** | SwiftUI |
| **Authentication**| Firebase Auth (with Sign in with Apple) |
| **Secure Storage**| macOS Keychain (via Security framework) |
| **CI/CD** | GitHub Actions |
| **Dependencies**| Swift Package Manager |

## 📂 Project Structure

The project follows a feature-based architecture to keep code organized and maintainable.

```
kura-macos/
├── .github/workflows/ci.yml    # GitHub Actions CI/CD pipeline
├── .claude/                    # Hooks for automated development standards
├── Kura/
│   ├── Kura.xcodeproj/         # Xcode Project
│   └── Kura/                   # Main source code directory
│       ├── App/                # App entry point (AppDelegate, KuraApp)
│       ├── Core/               # Business logic (Auth, API clients)
│       ├── Design/             # Design System (Theme.swift)
│       ├── Features/           # UI screens (Login, Dashboard, etc.)
│       ├── Assets.xcassets/    # Colors, icons, and other assets
│       └── ...
└── README.md                   # This file
```

## 🤝 Contributing

Contributions are what make the open-source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

This project enforces two main standards for contributions:
1.  **Branch Taxonomy:** Please create branches using prefixes like `feat/`, `fix/`, or `chore/`. (e.g., `feat/new-login-animation`).
2.  **Conventional Commits:** Commit messages must follow the [Conventional Commits specification](https://www.conventionalcommits.org/en/v1.0.0/).

## 📜 License

Distributed under the MIT License. See `LICENSE` for more information.
