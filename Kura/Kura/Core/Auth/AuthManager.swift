// AuthManager.swift
// Coordena Sign in with Apple + Firebase Auth
// Firebase imports descomentados após adicionar via SPM

import Foundation
import Combine
import AuthenticationServices
import CryptoKit
// import FirebaseAuth  // TODO(fase-0): descomentar após SPM

// MARK: - Auth State

enum AuthState: Equatable {
    case unknown
    case signedOut
    case signedIn(userID: String)
}

// MARK: - AuthManager

@MainActor
final class AuthManager: NSObject, ObservableObject {
    static let shared = AuthManager()

    @Published var authState: AuthState = .unknown

    private var currentNonce: String?

    override private init() {
        super.init()
        restoreSession()
    }

    // MARK: - Session restore

    private func restoreSession() {
        do {
            let userID = try KeychainHelper.shared.loadAppleUserID()
            authState = .signedIn(userID: userID)
        } catch {
            authState = .signedOut
        }
    }

    // MARK: - Sign in with Apple

    func startSignInWithApple() -> ASAuthorizationController {
        let nonce = randomNonce()
        currentNonce = nonce

        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        return controller
    }

    // MARK: - Sign out

    func signOut() {
        do {
            try KeychainHelper.shared.deleteFirebaseToken()
            try KeychainHelper.shared.delete(for: KeychainHelper.Keys.appleUserID)
        } catch {
            print("[AuthManager] signOut keychain cleanup error: \(error)")
        }
        authState = .signedOut
    }

    // MARK: - Nonce helpers (PKCE-style for Apple Auth)

    private func randomNonce(length: Int = 32) -> String {
        var randomBytes = [UInt8](repeating: 0, count: length)
        let result = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        guard result == errSecSuccess else {
            fatalError("[AuthManager] Unable to generate nonce")
        }
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    private func sha256(_ input: String) -> String {
        let data = Data(input.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AuthManager: ASAuthorizationControllerDelegate {
    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            return
        }

        let userID = appleIDCredential.user

        // TODO(fase-0): trocar token Apple por Firebase credential
        // guard let nonce = currentNonce,
        //       let appleIDToken = appleIDCredential.identityToken,
        //       let idTokenString = String(data: appleIDToken, encoding: .utf8) else { return }
        // let credential = OAuthProvider.appleCredential(withIDToken: idTokenString, rawNonce: nonce, fullName: appleIDCredential.fullName)
        // Auth.auth().signIn(with: credential) { [weak self] result, error in ... }

        Task { @MainActor in
            do {
                try KeychainHelper.shared.saveAppleUserID(userID)
                self.authState = .signedIn(userID: userID)
            } catch {
                print("[AuthManager] Keychain save error: \(error)")
            }
        }
    }

    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        print("[AuthManager] Sign in with Apple error: \(error.localizedDescription)")
    }
}
