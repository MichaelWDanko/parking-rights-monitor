//
//  PreviewEnvironment.swift
//  Passport API Explorer
//
//  Created by Assistant on 10/31/25.
//

import Foundation

enum PreviewEnvironment {
    static func makePreviewService() -> PassportAPIService {
        let config = OAuthConfiguration(
            baseURL: "https://example.com",
            tokenURL: URL(string: "https://example.com/token")!,
            client_id: "test",
            client_secret: "test",
            audience: "preview",
            clientTraceId: "preview"
        )
        return PassportAPIService(config: config)
    }
    
    /// Creates a preview APIServiceManager with test credentials for all environments.
    /// This allows Preview code to work without requiring actual Keychain/Secrets.json credentials.
    static func makePreviewAPIServiceManager() -> APIServiceManager {
        // Save test credentials to Keychain for all environments
        // This ensures APIServiceManager can create services for previews
        let keychainService = KeychainService()
        let testClientId = "preview_test_client_id_123456789012"
        let testClientSecret = "preview_test_client_secret_12345678901234567890"
        
        // Save test credentials for all environments
        for environment in OperatorEnvironment.allCases {
            do {
                try keychainService.saveCredentials(
                    clientId: testClientId,
                    clientSecret: testClientSecret,
                    for: environment
                )
            } catch {
                // If saving fails (e.g., in some preview contexts), continue anyway
                // The APIServiceManager will handle missing credentials gracefully
                print("⚠️ [PreviewEnvironment] Could not save test credentials for \(environment.rawValue): \(error)")
            }
        }
        
        // Create and return the manager
        return APIServiceManager(clientTraceId: "preview")
    }
}


