// LoginView.swift
// Tela de login — Sign in with Apple

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject private var authManager: AuthManager
    @ObservedObject private var popoverVisibility = PopoverVisibility.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var motionEnabled: Bool { popoverVisibility.isShown && !reduceMotion }

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
                        .symbolEffect(.pulse.byLayer, isActive: motionEnabled)

                    Text("Kura")
                        .font(KuraFont.primaryBold(size: 32))
                        .foregroundStyle(Color.kuraText)

                    Text("Seu assistente de conhecimento")
                        .font(KuraFont.body)
                        .foregroundStyle(Color.kuraTextMuted)
                }

                Spacer()

                // Sign in with Apple — glass interativo em macOS 26; aparência do
                // sistema inalterada em versões anteriores (Apple HIG).
                KuraGlassContainer {
                    SignInWithAppleButton(.signIn) { request in
                        authManager.prepareSignInRequest(request)
                    } onCompletion: { result in
                        switch result {
                        case .success(let authorization):
                            authManager.completeSignIn(authorization: authorization)
                        case .failure(let error):
                            print("[LoginView] Sign in error: \(error.localizedDescription)")
                        }
                    }
                    .signInWithAppleButtonStyle(.white)
                    .frame(width: 280, height: 44)
                    .clipShape(.rect(cornerRadius: KuraLayout.cornerRadius))
                    .kuraGlass(interactive: true)
                }

                #if DEBUG
                Button("Dev Sign In") { authManager.debugSignIn() }
                    .font(KuraFont.caption)
                    .foregroundStyle(Color.kuraTextMuted)
                #endif

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
}

#Preview {
    LoginView()
        .environmentObject(AuthManager.shared)
}
