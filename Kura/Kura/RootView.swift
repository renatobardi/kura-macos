// RootView.swift
// Roteador raiz: mostra LoginView ou DashboardView conforme authState

import SwiftUI

struct RootView: View {
    @StateObject private var authManager = AuthManager.shared

    var body: some View {
        Group {
            switch authManager.authState {
            case .unknown:
                // Estado breve durante o restore async do Keychain — mostra a marca
                // em vez de um popover vazio (no macOS 26 o fundo é o glass do OS).
                ZStack {
                    KuraAdaptiveBackground()
                    Image(systemName: "sparkles")
                        .font(.system(size: 36, weight: .thin))
                        .foregroundStyle(Color.kuraAccent)
                }
                .frame(width: KuraLayout.popoverWidth, height: KuraLayout.popoverHeight)
            case .signedOut:
                LoginView()
                    .environmentObject(authManager)
            case .signedIn:
                DashboardView()
                    .environmentObject(authManager)
            }
        }
    }
}

#Preview {
    RootView()
}
