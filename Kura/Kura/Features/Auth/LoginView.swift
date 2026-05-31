// LoginView.swift
// Tela de login — Sign in with Apple

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject private var authManager: AuthManager
    @State private var pendingNonce: String?

    var body: some View {
        ZStack {
            Color.kuraBackground.ignoresSafeArea()

            VStack(spacing: KuraSpacing.xl) {
                Spacer()

                // Logo / marca
                VStack(spacing: KuraSpacing.sm) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 48, weight: .thin))
                        .foregroundStyle(Color.kuraAccent)

                    Text("Kura")
                        .font(KuraFont.primaryBold(size: 32))
                        .foregroundStyle(Color.kuraText)

                    Text("Seu assistente de conhecimento")
                        .font(KuraFont.body)
                        .foregroundStyle(Color.kuraTextMuted)
                }

                Spacer()

                // Sign in with Apple
                SignInWithAppleButton(.signIn) { request in
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

    private func handleAuthorization(_ authorization: ASAuthorization, rawNonce: String) {
        authManager.completeSignIn(authorization: authorization, rawNonce: rawNonce)
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthManager.shared)
}
