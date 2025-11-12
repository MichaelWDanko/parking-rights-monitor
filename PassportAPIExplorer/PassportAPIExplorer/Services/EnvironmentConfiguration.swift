//
//  EnvironmentConfiguration.swift
//  Passport API Explorer
//
//  Created by Michael Danko on 11/11/25.
//

import Foundation

/// Configuration for API endpoints per environment.
/// Maps each OperatorEnvironment to its corresponding base URL and token endpoint.
struct EnvironmentConfiguration {
    let baseURL: String
    let tokenURL: URL
    let audience: String
    
    /// Get configuration for a specific environment
    static func configuration(for environment: OperatorEnvironment) -> EnvironmentConfiguration {
        switch environment {
        case .production:
            return EnvironmentConfiguration(
                baseURL: "https://api.us.passportinc.com",
                tokenURL: URL(string: "https://api.us.passportinc.com/v3/shared/access-tokens")!,
                audience: "public.api.passportinc.com"
            )
        case .staging:
            return EnvironmentConfiguration(
                baseURL: "https://api.staging.passportinc.com",
                tokenURL: URL(string: "https://api.staging.passportinc.com/v3/shared/access-tokens")!,
                audience: "public.api.passportinc.com"
            )
        case .development:
            return EnvironmentConfiguration(
                baseURL: "https://api.dev.passportinc.com",
                tokenURL: URL(string: "https://api.dev.passportinc.com/v3/shared/access-tokens")!,
                audience: "public.api.passportinc.com"
            )
        }
    }
    
    /// Display name for the environment (used in UI)
    static func displayName(for environment: OperatorEnvironment) -> String {
        switch environment {
        case .production:
            return "Production"
        case .staging:
            return "Staging"
        case .development:
            return "Development"
        }
    }
}

