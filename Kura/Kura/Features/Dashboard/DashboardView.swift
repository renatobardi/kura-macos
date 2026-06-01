// DashboardView.swift
// Placeholder pós-login — Fase 0
// Fase 4 vai implementar o dashboard diário completo

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var authManager: AuthManager
    @ObservedObject private var popoverVisibility = PopoverVisibility.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @State private var signOutTapped = false

    private var motionEnabled: Bool { popoverVisibility.isShown && !reduceMotion }

    var body: some View {
        ZStack {
            KuraAdaptiveBackground()

            VStack(spacing: KuraSpacing.xl) {
                // Header
                header
                    .padding(.horizontal, KuraSpacing.xl)
                    .padding(.top, KuraSpacing.xl)

                // Sem glass (macOS <26 ou Reduzir transparência), o divider provê a separação.
                if !KuraGlass.isActive(reduceTransparency: reduceTransparency) {
                    Divider()
                        .background(Color.kuraDivider)
                        .padding(.horizontal, KuraSpacing.xl)
                }

                // Placeholder fase 0
                Spacer()

                VStack(spacing: KuraSpacing.md) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 36, weight: .thin))
                        .foregroundStyle(Color.kuraAccent)
                        .symbolEffect(.variableColor.iterative, isActive: motionEnabled)

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

    private var header: some View {
        // Glass vive só na barra do header (chrome). O botão é plain sobre ela —
        // glass dentro de glass amostraria o próprio fundo e gera artefato.
        HStack {
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
        .padding(KuraSpacing.md)
        .kuraGlass()
    }
}

#Preview {
    DashboardView()
        .environmentObject(AuthManager.shared)
}
