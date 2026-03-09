//
//  ServicesKeychainServiceTests.swift
//  pantryTests
//

import Testing
import Foundation
@testable import pantry

struct KeychainServiceTests {

    @Test func loadAPIKey_migratesLegacyUserDefaultsValue_whenKeychainEmpty() {
        let defaults = UserDefaults(suiteName: "KeychainServiceTests.migrate.\(UUID().uuidString)")!
        let store = InMemoryKeychainStore()
        let service = KeychainService(store: store, userDefaults: defaults)

        defaults.set("legacy-key", forKey: KeychainService.keyName)

        let loaded = service.loadAPIKey()

        #expect(loaded == "legacy-key")
        #expect(store.read(key: KeychainService.keyName) == "legacy-key")
        #expect(defaults.string(forKey: KeychainService.keyName) == nil)
    }

    @Test func loadAPIKey_prefersKeychainValue_overLegacyUserDefaults() {
        let defaults = UserDefaults(suiteName: "KeychainServiceTests.prefer.\(UUID().uuidString)")!
        let store = InMemoryKeychainStore()
        let service = KeychainService(store: store, userDefaults: defaults)

        store.write("keychain-key", key: KeychainService.keyName)
        defaults.set("legacy-key", forKey: KeychainService.keyName)

        let loaded = service.loadAPIKey()

        #expect(loaded == "keychain-key")
        #expect(defaults.string(forKey: KeychainService.keyName) == "legacy-key")
    }

    @Test func saveAPIKey_writesToKeychain_andClearsLegacyDefaults() {
        let defaults = UserDefaults(suiteName: "KeychainServiceTests.save.\(UUID().uuidString)")!
        let store = InMemoryKeychainStore()
        let service = KeychainService(store: store, userDefaults: defaults)

        defaults.set("legacy-key", forKey: KeychainService.keyName)
        service.saveAPIKey("new-key")

        #expect(store.read(key: KeychainService.keyName) == "new-key")
        #expect(defaults.string(forKey: KeychainService.keyName) == nil)
    }

    @Test func saveAPIKey_emptyStringDeletesKeychainValue() {
        let defaults = UserDefaults(suiteName: "KeychainServiceTests.delete.\(UUID().uuidString)")!
        let store = InMemoryKeychainStore()
        let service = KeychainService(store: store, userDefaults: defaults)

        service.saveAPIKey("persisted-key")
        service.saveAPIKey(" ")

        #expect(store.read(key: KeychainService.keyName) == nil)
    }
}

