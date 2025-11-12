//
//  KeychainService.swift
//  Passport API Explorer
//
//  Created by Michael Danko on 11/11/25.
//

import Foundation
import Security

/// Errors that can occur during Keychain operations
enum KeychainError: Error, LocalizedError {
    case unableToSave
    case unableToLoad
    case unableToDelete
    case itemNotFound
    case unexpectedData
    
    var errorDescription: String? {
        switch self {
        case .unableToSave:
            return "Unable to save credentials to Keychain"
        case .unableToLoad:
            return "Unable to load credentials from Keychain"
        case .unableToDelete:
            return "Unable to delete credentials from Keychain"
        case .itemNotFound:
            return "Credentials not found in Keychain"
        case .unexpectedData:
            return "Unexpected data format in Keychain"
        }
    }
}

/// Service for securely storing and retrieving OAuth credentials using iOS Keychain.
/// Credentials are stored per environment and never leave the device.
class KeychainService {
    
    private let service = "com.michaelwdanko.PassportAPIExplorer"
    
    // MARK: - Public Methods
    
    /// Save OAuth credentials for a specific environment
    func saveCredentials(clientId: String, clientSecret: String, for environment: OperatorEnvironment) throws {
        // Save client_id
        try saveToKeychain(value: clientId, key: keychainKey(for: environment, type: .clientId))
        // Save client_secret
        try saveToKeychain(value: clientSecret, key: keychainKey(for: environment, type: .clientSecret))
        
        print("✅ [Keychain] Saved credentials for \(environment.rawValue)")
    }
    
    /// Load OAuth credentials for a specific environment
    func loadCredentials(for environment: OperatorEnvironment) throws -> (clientId: String, clientSecret: String) {
        let clientId = try loadFromKeychain(key: keychainKey(for: environment, type: .clientId))
        let clientSecret = try loadFromKeychain(key: keychainKey(for: environment, type: .clientSecret))
        
        print("✅ [Keychain] Loaded credentials for \(environment.rawValue)")
        return (clientId, clientSecret)
    }
    
    /// Delete OAuth credentials for a specific environment
    func deleteCredentials(for environment: OperatorEnvironment) throws {
        try deleteFromKeychain(key: keychainKey(for: environment, type: .clientId))
        try deleteFromKeychain(key: keychainKey(for: environment, type: .clientSecret))
        
        print("✅ [Keychain] Deleted credentials for \(environment.rawValue)")
    }
    
    /// Check if credentials exist for a specific environment
    func hasCredentials(for environment: OperatorEnvironment) -> Bool {
        do {
            _ = try loadCredentials(for: environment)
            return true
        } catch {
            return false
        }
    }
    
    // MARK: - Private Helpers
    
    private enum CredentialType: String {
        case clientId = "client_id"
        case clientSecret = "client_secret"
    }
    
    /// Generate a unique Keychain key for environment + credential type
    private func keychainKey(for environment: OperatorEnvironment, type: CredentialType) -> String {
        return "\(environment.rawValue)_\(type.rawValue)"
    }
    
    /// Save a string value to Keychain
    private func saveToKeychain(value: String, key: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.unexpectedData
        }
        
        // First, try to delete any existing item with this key
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(deleteQuery as CFDictionary)
        
        // Add the new item
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            print("❌ [Keychain] Failed to save \(key): \(status)")
            throw KeychainError.unableToSave
        }
    }
    
    /// Load a string value from Keychain
    private func loadFromKeychain(key: String) throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                throw KeychainError.itemNotFound
            }
            print("❌ [Keychain] Failed to load \(key): \(status)")
            throw KeychainError.unableToLoad
        }
        
        guard let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            throw KeychainError.unexpectedData
        }
        
        return value
    }
    
    /// Delete a value from Keychain
    private func deleteFromKeychain(key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            print("❌ [Keychain] Failed to delete \(key): \(status)")
            throw KeychainError.unableToDelete
        }
    }
}

