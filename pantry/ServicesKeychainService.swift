//
//  ServicesKeychainService.swift
//  pantry
//
//  Secure persistence for assistant API keys.
//

import Foundation
import Security

protocol KeychainStoring {
    func read(key: String) -> String?
    func write(_ value: String, key: String)
    func delete(key: String)
}

struct SystemKeychainStore: KeychainStoring {

    private let service = "foundation.pantry"

    func read(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess,
              let data = item as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        return value
    }

    func write(_ value: String, key: String) {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]

        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecSuccess {
            return
        }

        var insertQuery = query
        insertQuery[kSecValueData as String] = data
        SecItemAdd(insertQuery as CFDictionary, nil)
    }

    func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}

final class InMemoryKeychainStore: KeychainStoring {
    private var values: [String: String] = [:]

    func read(key: String) -> String? { values[key] }
    func write(_ value: String, key: String) { values[key] = value }
    func delete(key: String) { values.removeValue(forKey: key) }
}

struct KeychainService {

    static let keyName = "anthropic_api_key"

    private let store: KeychainStoring
    private let userDefaults: UserDefaults

    init(
        store: KeychainStoring = SystemKeychainStore(),
        userDefaults: UserDefaults = .standard
    ) {
        self.store = store
        self.userDefaults = userDefaults
    }

    /// Returns the active API key, migrating from legacy UserDefaults storage if needed.
    func loadAPIKey() -> String {
        if let secure = store.read(key: Self.keyName),
           !secure.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return secure
        }

        let legacy = userDefaults.string(forKey: Self.keyName)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !legacy.isEmpty else { return "" }

        store.write(legacy, key: Self.keyName)
        userDefaults.removeObject(forKey: Self.keyName)
        return legacy
    }

    /// Persists the API key in Keychain. Empty values delete the key.
    func saveAPIKey(_ key: String) {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            store.delete(key: Self.keyName)
        } else {
            store.write(trimmed, key: Self.keyName)
        }
        // Always clear legacy location to keep a single source of truth.
        userDefaults.removeObject(forKey: Self.keyName)
    }
}

