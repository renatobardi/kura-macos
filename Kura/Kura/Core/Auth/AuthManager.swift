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

    func completeSignIn(authorization: ASAuthorization, rawNonce: String) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            return
        }

        let userID = appleIDCredential.user

        // TODO(fase-0): trocar token Apple por Firebase credential
        // guard let appleIDToken = appleIDCredential.identityToken,
        //       let idTokenString = String(data: appleIDToken, encoding: .utf8) else { return }
        // let credential = OAuthProvider.appleCredential(withIDToken: idTokenString, rawNonce: rawNonce, fullName: appleIDCredential.fullName)
        // Auth.auth().signIn(with: credential) { [weak self] result, error in ... }

        do {
            try KeychainHelper.shared.saveAppleUserID(userID)
            authState = .signedIn(userID: userID)
        } catch {
            print("[AuthManager] Keychain save error: \(error)")
        }
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
        var randomBytes = [UInt8](repeating: 0, count: length)
        let result = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        guard result == errSecSuccess else {
            fatalError("[AuthManager] Unable to generate nonce")
        }
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    static func sha256(_ input: String) -> String {
        let data = Data(input.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}
