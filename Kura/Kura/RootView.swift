// RootView.swift
// Roteador raiz: mostra LoginView ou DashboardView conforme authState

import SwiftUI

struct RootView: View {
    @StateObject private var authManager = AuthManager.shared

    var body: some View {
        Group {
            switch authManager.authState {
            case .unknown:
                KuraAdaptiveBackground()
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
