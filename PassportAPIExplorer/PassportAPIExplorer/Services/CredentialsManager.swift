//
//  CredentialsManager.swift
//  Passport API Explorer
//
//  Created by Michael Danko on 11/11/25.
//

import Foundation

/// Manages OAuth credentials across environments.
/// Production credentials come from Secrets.json (shipped with app).
/// Staging/Dev credentials come from Keychain (user-provided).
/// Production credentials can be overridden by user via Keychain.
class CredentialsManager {
    
    private let keychainService = KeychainService()
    
    // MARK: - Public Methods
    
    /// Check if a value is a placeholder (contains angle brackets or common placeholder patterns)
    /// Also validates that client secrets are the correct length (64 characters as required by API)
    private func isPlaceholder(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let lowercased = trimmed.lowercased()
        
        // Check for common placeholder patterns
        if trimmed.contains("<") && trimmed.contains(">") ||
           lowercased.contains("your_") ||
           lowercased.contains("placeholder") ||
           lowercased == "test" ||
           trimmed.isEmpty {
            return true
        }
        
        // Client secrets must be exactly 64 characters per API requirements
        // Client IDs are 32 characters
        // Reject suspiciously short values (likely test/placeholder values)
        if trimmed.count < 10 {
            return true
        }
        
        return false
    }
    
    /// Get credentials for a specific environment
    /// Priority: Keychain (user-provided) > Secrets.json (shipped with app)
    func getCredentials(for environment: OperatorEnvironment) -> (clientId: String, clientSecret: String)? {
        // First, check if Keychain has credentials
        let hasKeychainCreds = keychainService.hasCredentials(for: environment)
        print("📦 [CredentialsManager] Checking credentials for \(environment.rawValue)...")
        print("📦 [CredentialsManager] Keychain has credentials: \(hasKeychainCreds)")
        
        // First, try to load from Keychain (user-provided or overridden)
        if let credentials = try? keychainService.loadCredentials(for: environment) {
            print("📦 [CredentialsManager] ✅ Using Keychain credentials for \(environment.rawValue)")
            print("📦 [CredentialsManager] Keychain Client ID: \"\(credentials.clientId)\"")
            print("📦 [CredentialsManager] Keychain Client ID length: \(credentials.clientId.count) characters")
            print("📦 [CredentialsManager] Keychain Client ID preview: \(credentials.clientId.prefix(8))...\(credentials.clientId.suffix(4))")
            print("📦 [CredentialsManager] Keychain Client Secret: \"\(credentials.clientSecret)\"")
            print("📦 [CredentialsManager] Keychain Client Secret length: \(credentials.clientSecret.count) characters")
            
            // Validate Keychain credentials aren't placeholders
            if isPlaceholder(credentials.clientId) {
                print("⚠️ [CredentialsManager] Keychain Client ID is a placeholder: \"\(credentials.clientId)\"")
                print("⚠️ [CredentialsManager] Treating Keychain credentials as invalid, will fall back to Secrets.json")
                return nil
            }
            if isPlaceholder(credentials.clientSecret) {
                print("⚠️ [CredentialsManager] Keychain Client Secret is a placeholder: \"\(credentials.clientSecret)\"")
                print("⚠️ [CredentialsManager] Treating Keychain credentials as invalid, will fall back to Secrets.json")
                return nil
            }
            
            return credentials
        } else if hasKeychainCreds {
            print("⚠️ [CredentialsManager] Keychain reports credentials exist but failed to load them")
        }
        
        // Fall back to Secrets.json (shipped with app) for all environments
        print("📦 [CredentialsManager] Falling back to Secrets.json for \(environment.rawValue)")
        if let envCredentials = try? SecretsLoader.credentials(for: environment) {
            print("📦 [CredentialsManager] ✅ Using Secrets.json credentials for \(environment.rawValue)")
            print("📦 [CredentialsManager] Secrets.json Client ID: \"\(envCredentials.client_id)\"")
            print("📦 [CredentialsManager] Secrets.json Client ID length: \(envCredentials.client_id.count) characters")
            print("📦 [CredentialsManager] Secrets.json Client ID preview: \(envCredentials.client_id.prefix(8))...\(envCredentials.client_id.suffix(4))")
            print("📦 [CredentialsManager] Secrets.json Client ID trimmed length: \(envCredentials.client_id.trimmingCharacters(in: .whitespacesAndNewlines).count) characters")
            print("📦 [CredentialsManager] Secrets.json Client Secret: \"\(envCredentials.client_secret)\"")
            print("📦 [CredentialsManager] Secrets.json Client Secret length: \(envCredentials.client_secret.count) characters")
            print("📦 [CredentialsManager] Secrets.json Client Secret trimmed length: \(envCredentials.client_secret.trimmingCharacters(in: .whitespacesAndNewlines).count) characters")
            
            // Return trimmed values to avoid whitespace issues
            let trimmedClientId = envCredentials.client_id.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedClientSecret = envCredentials.client_secret.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Validate credentials aren't placeholders
            if isPlaceholder(trimmedClientId) {
                print("⚠️ [CredentialsManager] Client ID is a placeholder: \"\(trimmedClientId)\"")
                print("⚠️ [CredentialsManager] Please update Secrets.json with actual credentials for \(environment.rawValue)")
                return nil
            }
            
            if isPlaceholder(trimmedClientSecret) {
                print("⚠️ [CredentialsManager] Client Secret is a placeholder: \"\(trimmedClientSecret)\"")
                print("⚠️ [CredentialsManager] Please update Secrets.json with actual credentials for \(environment.rawValue)")
                return nil
            }
            
            print("📦 [CredentialsManager] Returning trimmed values:")
            print("📦 [CredentialsManager]   - Client ID: \"\(trimmedClientId)\"")
            print("📦 [CredentialsManager]   - Client Secret: \"\(trimmedClientSecret)\"")
            return (trimmedClientId, trimmedClientSecret)
        }
        
        print("⚠️ [CredentialsManager] No credentials available for \(environment.rawValue)")
        return nil
    }
    
    /// Save credentials for an environment to Keychain
    func saveCredentials(clientId: String, clientSecret: String, for environment: OperatorEnvironment) throws {
        try keychainService.saveCredentials(clientId: clientId, clientSecret: clientSecret, for: environment)
        print("✅ [CredentialsManager] Saved credentials for \(environment.rawValue)")
    }
    
    /// Delete credentials for an environment from Keychain
    func deleteCredentials(for environment: OperatorEnvironment) throws {
        try keychainService.deleteCredentials(for: environment)
        print("✅ [CredentialsManager] Deleted credentials for \(environment.rawValue)")
    }
    
    /// Check if an environment is configured (has credentials available)
    func isConfigured(environment: OperatorEnvironment) -> Bool {
        // Check Keychain first
        if keychainService.hasCredentials(for: environment) {
            return true
        }
        
        // Check Secrets.json for all environments
        if let _ = try? SecretsLoader.credentials(for: environment) {
            return true
        }
        
        return false
    }
    
    /// Get configuration status for all environments
    func getConfigurationStatus() -> [OperatorEnvironment: Bool] {
        return [
            .production: isConfigured(environment: .production),
            .staging: isConfigured(environment: .staging),
            .development: isConfigured(environment: .development)
        ]
    }
    
    /// Check if an environment has user-provided credentials in Keychain
    /// (as opposed to default Secrets.json credentials)
    func hasUserProvidedCredentials(for environment: OperatorEnvironment) -> Bool {
        return keychainService.hasCredentials(for: environment)
    }
    
    /// Get the client_id for display purposes (used in UI)
    /// Returns nil if no credentials are available
    func getClientId(for environment: OperatorEnvironment) -> String? {
        return getCredentials(for: environment)?.clientId
    }
}

