//
//  APIServiceManager.swift
//  Passport API Explorer
//
//  Created by Michael Danko on 11/11/25.
//

import Foundation
import Combine

/// Manages PassportAPIService instances for different environments.
/// Creates and maintains a separate service instance per environment with the correct
/// base URL and credentials. Provides environment-aware access to services.
class APIServiceManager: ObservableObject {
    
    private let credentialsManager = CredentialsManager()
    private var services: [OperatorEnvironment: PassportAPIService] = [:]
    private let clientTraceId: String
    
    init(clientTraceId: String = "danko-test") {
        self.clientTraceId = clientTraceId
        
        // Initialize services for all environments
        for environment in OperatorEnvironment.allCases {
            if let service = createService(for: environment) {
                services[environment] = service
                print("✅ [APIServiceManager] Initialized service for \(environment.rawValue)")
            } else {
                print("⚠️ [APIServiceManager] No credentials available for \(environment.rawValue)")
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// Get the PassportAPIService for a specific environment
    /// Returns nil if the environment is not configured with credentials
    func service(for environment: OperatorEnvironment) -> PassportAPIService? {
        // If service doesn't exist, try to create it
        if services[environment] == nil {
            services[environment] = createService(for: environment)
        }
        return services[environment]
    }
    
    /// Get the PassportAPIService for a specific operator
    /// Returns nil if the operator's environment is not configured
    func service(forOperator op: Operator) -> PassportAPIService? {
        guard let environment = op.environment else {
            print("⚠️ [APIServiceManager] Operator \(op.name) has no environment")
            return nil
        }
        return service(for: environment)
    }
    
    /// Refresh the service for a specific environment
    /// Useful after credentials are updated
    func refreshService(for environment: OperatorEnvironment) {
        services[environment] = createService(for: environment)
        if services[environment] != nil {
            print("✅ [APIServiceManager] Refreshed service for \(environment.rawValue)")
        } else {
            print("⚠️ [APIServiceManager] Failed to refresh service for \(environment.rawValue)")
        }
    }
    
    /// Refresh all services (useful after credentials are updated)
    func refreshAllServices() {
        for environment in OperatorEnvironment.allCases {
            refreshService(for: environment)
        }
    }
    
    /// Check if an environment is configured with valid credentials
    func isConfigured(environment: OperatorEnvironment) -> Bool {
        return credentialsManager.isConfigured(environment: environment)
    }
    
    /// Get configuration status for all environments
    func getConfigurationStatus() -> [OperatorEnvironment: Bool] {
        return credentialsManager.getConfigurationStatus()
    }
    
    // MARK: - Private Methods
    
    /// Create a PassportAPIService instance for a specific environment
    private func createService(for environment: OperatorEnvironment) -> PassportAPIService? {
        print("🔧 [APIServiceManager] Creating service for \(environment.rawValue)")
        
        // Get credentials for this environment
        guard let credentials = credentialsManager.getCredentials(for: environment) else {
            print("⚠️ [APIServiceManager] No credentials for \(environment.rawValue)")
            return nil
        }
        
        print("🔧 [APIServiceManager] Credentials retrieved for \(environment.rawValue)")
        print("🔧 [APIServiceManager] Client ID length: \(credentials.clientId.count) characters")
        print("🔧 [APIServiceManager] Client ID value: \"\(credentials.clientId)\"")
        print("🔧 [APIServiceManager] Client ID contains only alphanumeric: \(credentials.clientId.allSatisfy { $0.isLetter || $0.isNumber })")
        print("🔧 [APIServiceManager] Client ID matches pattern [A-Za-z0-9]{32}: \(NSPredicate(format: "SELF MATCHES %@", "^[A-Za-z0-9]{32}$").evaluate(with: credentials.clientId))")
        
        // Get environment configuration (base URL, token URL, etc.)
        let envConfig = EnvironmentConfiguration.configuration(for: environment)
        print("🔧 [APIServiceManager] Base URL: \(envConfig.baseURL)")
        print("🔧 [APIServiceManager] Token URL: \(envConfig.tokenURL)")
        
        // Create OAuth configuration
        let oauthConfig = OAuthConfiguration(
            baseURL: envConfig.baseURL,
            tokenURL: envConfig.tokenURL,
            client_id: credentials.clientId,
            client_secret: credentials.clientSecret,
            audience: envConfig.audience,
            clientTraceId: clientTraceId
        )
        
        print("🔧 [APIServiceManager] OAuth config created with Client ID: \"\(oauthConfig.client_id)\"")
        print("🔧 [APIServiceManager] OAuth config Client ID length: \(oauthConfig.client_id.count)")
        
        // Create and return service instance
        return PassportAPIService(config: oauthConfig, clientTraceId: clientTraceId)
    }
}

