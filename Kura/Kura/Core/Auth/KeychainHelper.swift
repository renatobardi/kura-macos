// KeychainHelper.swift
// Wrapper seguro para Security framework — NUNCA use UserDefaults para tokens

import Foundation
import Security

enum KeychainError: LocalizedError {
    case unhandledError(status: OSStatus)
    case itemNotFound
    case unexpectedData

    var errorDescription: String? {
        switch self {
        case .unhandledError(let status):
            return "Keychain error: \(status)"
        case .itemNotFound:
            return "Item not found in Keychain"
        case .unexpectedData:
            return "Unexpected data format in Keychain"
        }
    }
}

final class KeychainHelper {
    static let shared = KeychainHelper()
    private init() {}

    private let service = "pro.oute.kura"

    // MARK: - Save

    @discardableResult
    func save(_ value: String, for key: String) throws -> Bool {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.unexpectedData
        }

        let query: [String: Any] = [
            kSecClass as String:            kSecClassGenericPassword,
            kSecAttrService as String:      service,
            kSecAttrAccount as String:      key,
            kSecValueData as String:        data,
            kSecAttrAccessible as String:   kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        // Delete existing before saving
        SecItemDelete(query as CFDictionary)

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }
        return true
    }

    // MARK: - Load

    func load(for key: String) throws -> String {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String:  true,
            kSecMatchLimit as String:  kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status != errSecItemNotFound else {
            throw KeychainError.itemNotFound
        }
        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }
        guard let data = result as? Data, let value = String(data: data, encoding: .utf8) else {
            throw KeychainError.unexpectedData
        }
        return value
    }

    // MARK: - Delete

    @discardableResult
    func delete(for key: String) throws -> Bool {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandledError(status: status)
        }
        return true
    }

    // MARK: - Convenience: Auth tokens

    func saveFirebaseToken(_ token: String) throws {
        try save(token, for: Keys.firebaseToken)
    }

    func loadFirebaseToken() throws -> String {
        try load(for: Keys.firebaseToken)
    }

    func deleteFirebaseToken() throws {
        try delete(for: Keys.firebaseToken)
    }

    func saveAppleUserID(_ userID: String) throws {
        try save(userID, for: Keys.appleUserID)
    }

    func loadAppleUserID() throws -> String {
        try load(for: Keys.appleUserID)
    }

    // MARK: - Keys

    enum Keys {
        static let firebaseToken = "firebase_id_token"
        static let appleUserID   = "apple_user_id"
        static let appleNonce    = "apple_auth_nonce"
    }
}
