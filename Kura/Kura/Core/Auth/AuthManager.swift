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

    private var pendingNonce: String?

    override private init() {
        super.init()
        Task { @MainActor in
            await restoreSession()
        }
    }

    // MARK: - Session restore

    private func restoreSession() async {
        let userID = await Task.detached(priority: .userInitiated) {
            try? KeychainHelper.shared.loadAppleUserID()
        }.value

        authState = userID != nil ? .signedIn(userID: userID!) : .signedOut
    }

    // MARK: - Sign in with Apple

    /// Gera o nonce PKCE e o anexa ao request. O nonce cru é guardado aqui (no
    /// singleton persistente, não em @State de uma View) para sobreviver ao
    /// teardown do popover transient entre o request e o completion.
    func prepareSignInRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = Self.randomNonce()
        pendingNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = Self.sha256(nonce)
    }

    func completeSignIn(authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            print("[AuthManager] completeSignIn: tipo de credencial inesperado")
            return
        }
        guard pendingNonce != nil else {
            print("[AuthManager] completeSignIn: nonce ausente — sign-in abortado")
            return
        }

        let userID = appleIDCredential.user

        // TODO(fase-0): trocar token Apple por Firebase credential.
        //   let rawNonce = pendingNonce!  // hash deste valor foi enviado em request.nonce
        //   guard let appleIDToken = appleIDCredential.identityToken,
        //         let idTokenString = String(data: appleIDToken, encoding: .utf8) else { return }
        //   let credential = OAuthProvider.appleCredential(withIDToken: idTokenString, rawNonce: rawNonce, fullName: appleIDCredential.fullName)
        //   Auth.auth().signIn(with: credential) { [weak self] result, error in ... }

        do {
            try KeychainHelper.shared.saveAppleUserID(userID)
            authState = .signedIn(userID: userID)
        } catch {
            print("[AuthManager] Keychain save error: \(error)")
        }
        pendingNonce = nil
    }

    // MARK: - Sign out

    func signOut() {
        try? KeychainHelper.shared.deleteFirebaseToken()
        do {
            try KeychainHelper.shared.delete(for: KeychainHelper.Keys.appleUserID)
        } catch {
            print("[AuthManager] signOut: failed to delete appleUserID from Keychain: \(error)")
        }
        authState = .signedOut
    }

    // MARK: - Nonce helpers (PKCE-style for Apple Auth)

    static func randomNonce(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._")
        // Rejection sampling: descarta os bytes na cauda enviesada para que cada
        // caractere seja equiprovável (charset tem 65 chars, que não divide 256).
        let maxValid = UInt8(256 - (256 % charset.count) - 1)
        var nonce = ""
        nonce.reserveCapacity(length)
        while nonce.count < length {
            var byte: UInt8 = 0
            guard SecRandomCopyBytes(kSecRandomDefault, 1, &byte) == errSecSuccess else {
                fatalError("[AuthManager] Unable to generate nonce")
            }
            if byte <= maxValid {
                nonce.append(charset[Int(byte) % charset.count])
            }
        }
        return nonce
    }

    static func sha256(_ input: String) -> String {
        let data = Data(input.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}
