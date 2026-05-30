// DashboardView.swift
// Placeholder pós-login — Fase 0
// Fase 4 vai implementar o dashboard diário completo

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var authManager: AuthManager

    var body: some View {
        ZStack {
            Color.kuraBackground.ignoresSafeArea()

            VStack(spacing: KuraSpacing.xl) {
                // Header
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
                        authManager.signOut()
                    } label: {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 14, weight: .thin))
                            .foregroundStyle(Color.kuraTextMuted)
                    }
                    .buttonStyle(.plain)
                    .help("Sair")
                }
                .padding(.horizontal, KuraSpacing.xl)
                .padding(.top, KuraSpacing.xl)

                Divider()
                    .background(Color.kuraDivider)

                // Placeholder fase 0
                Spacer()

                VStack(spacing: KuraSpacing.md) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 36, weight: .thin))
                        .foregroundStyle(Color.kuraAccent)

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
}

#Preview {
    DashboardView()
        .environmentObject(AuthManager.shared)
}
