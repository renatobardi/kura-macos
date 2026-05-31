// DashboardView.swift
// Placeholder pós-login — Fase 0
// Fase 4 vai implementar o dashboard diário completo

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var authManager: AuthManager
    @State private var signOutTapped = false
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        ZStack {
            KuraAdaptiveBackground()

            VStack(spacing: KuraSpacing.xl) {
                // Header
                header
                    .padding(.horizontal, KuraSpacing.xl)
                    .padding(.top, KuraSpacing.xl)

                // Placeholder fase 0
                Spacer()

                VStack(spacing: KuraSpacing.md) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 36, weight: .thin))
                        .foregroundStyle(Color.kuraAccent)
                        .symbolEffect(.variableColor.iterative, isActive: true)

                    Text("Em construção")
                        .font(KuraFont.headline)
                        .foregroundStyle(Color.kuraText)

                    Text("Chat, Vault e Dashboard chegam em breve.")
                        .font(KuraFont.body)
                        .foregroundStyle(Color.kuraTextMuted)
                        .multilineTextAlignment(.center)
                }

                Spacer()
            }
        }
        .frame(width: KuraLayout.popoverWidth, height: KuraLayout.popoverHeight)
    }

    @ViewBuilder
    private var header: some View {
        let content = HStack {
            VStack(alignment: .leading, spacing: KuraSpacing.xs) {
                Text("Olá 👋")
                    .font(KuraFont.primaryMedium(size: 20))
                    .foregroundStyle(Color.kuraText)
                Text("O Kura está pronto.")
                    .font(KuraFont.body)
                    .foregroundStyle(Color.kuraTextMuted)
            }
            Spacer()

            Button {
                signOutTapped.toggle()
                authManager.signOut()
            } label: {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 14, weight: .thin))
                    .foregroundStyle(Color.kuraTextMuted)
                    .symbolEffect(.bounce, value: signOutTapped)
            }
            .buttonStyle(.plain)
            .help("Sair")
        }

        if #available(macOS 26, *), !reduceTransparency {
            GlassEffectContainer {
                content
                    .padding(KuraSpacing.md)
                    .glassEffect(.regular, in: .rect(cornerRadius: KuraLayout.cornerRadius))
            }
        } else {
            content
        }
    }
}

#Preview {
    DashboardView()
        .environmentObject(AuthManager.shared)
}
