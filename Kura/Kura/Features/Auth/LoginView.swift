// LoginView.swift
// Tela de login — Sign in with Apple

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject private var authManager: AuthManager
    @State private var pendingNonce: String?
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        ZStack {
            KuraAdaptiveBackground()

            VStack(spacing: KuraSpacing.xl) {
                Spacer()

                // Logo / marca
                VStack(spacing: KuraSpacing.sm) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 48, weight: .thin))
                        .foregroundStyle(Color.kuraAccent)
                        .symbolEffect(.pulse.byLayer, isActive: true)

                    Text("Kura")
                        .font(KuraFont.primaryBold(size: 32))
                        .foregroundStyle(Color.kuraText)

                    Text("Seu assistente de conhecimento")
                        .font(KuraFont.body)
                        .foregroundStyle(Color.kuraTextMuted)
                }

                Spacer()

                // Sign in with Apple
                signInSection

                Text("Ao continuar, você concorda com os termos de uso.")
                    .font(KuraFont.micro)
                    .foregroundStyle(Color.kuraTextMuted)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, KuraSpacing.xxl)
            }
            .padding(.horizontal, KuraSpacing.xxl)
        }
        .frame(width: KuraLayout.popoverWidth, height: KuraLayout.popoverHeight)
    }

    @ViewBuilder
    private var signInSection: some View {
        let button = SignInWithAppleButton(.signIn) { request in
            let nonce = AuthManager.randomNonce()
            pendingNonce = nonce
            request.requestedScopes = [.fullName, .email]
            request.nonce = AuthManager.sha256(nonce)
        } onCompletion: { result in
            switch result {
            case .success(let authorization):
                guard let rawNonce = pendingNonce else { return }
                handleAuthorization(authorization, rawNonce: rawNonce)
            case .failure(let error):
                print("[LoginView] Sign in error: \(error.localizedDescription)")
            }
        }
        .signInWithAppleButtonStyle(.white)
        .frame(width: 280, height: 44)
        .clipShape(.rect(cornerRadius: KuraLayout.cornerRadius))

        if #available(macOS 26, *), !reduceTransparency {
            GlassEffectContainer {
                button
                    .glassEffect(
                        .regular.interactive(),
                        in: .rect(cornerRadius: KuraLayout.cornerRadius)
                    )
            }
        } else {
            button
        }
    }

    private func handleAuthorization(_ authorization: ASAuthorization, rawNonce: String) {
        authManager.completeSignIn(authorization: authorization, rawNonce: rawNonce)
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthManager.shared)
}
