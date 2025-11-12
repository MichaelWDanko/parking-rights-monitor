//
//  APICredentialsViewModel.swift
//  Passport API Explorer
//
//  Created by Michael Danko on 11/11/25.
//

import Foundation
import SwiftUI

/// ViewModel for managing API credentials across environments
@Observable
class APICredentialsViewModel {
    
    private let credentialsManager = CredentialsManager()
    private let apiServiceManager: APIServiceManager
    
    // UI State
    var configurationStatus: [OperatorEnvironment: Bool] = [:]
    var isLoading = false
    var errorMessage: String?
    var successMessage: String?
    
    // Edit state for each environment
    var editingEnvironment: OperatorEnvironment?
    var editClientId = ""
    var editClientSecret = ""
    
    init(apiServiceManager: APIServiceManager) {
        self.apiServiceManager = apiServiceManager
        loadConfigurationStatus()
    }
    
    // MARK: - Public Methods
    
    /// Load configuration status for all environments
    func loadConfigurationStatus() {
        configurationStatus = credentialsManager.getConfigurationStatus()
    }
    
    /// Check if an environment is configured
    func isConfigured(environment: OperatorEnvironment) -> Bool {
        return configurationStatus[environment] ?? false
    }
    
    /// Get client ID for display (returns masked string if not available)
    func getClientId(for environment: OperatorEnvironment) -> String {
        if let clientId = credentialsManager.getClientId(for: environment) {
            return clientId
        }
        return "Not configured"
    }
    
    /// Get masked client secret for display
    func getMaskedSecret(for environment: OperatorEnvironment) -> String {
        if isConfigured(environment: environment) {
            return "••••••••••••••••"
        }
        return "Not configured"
    }
    
    /// Check if credentials are user-provided (in Keychain) vs default (Secrets.json)
    func hasUserProvidedCredentials(for environment: OperatorEnvironment) -> Bool {
        return credentialsManager.hasUserProvidedCredentials(for: environment)
    }
    
    /// Start editing credentials for an environment
    func startEditing(environment: OperatorEnvironment) {
        editingEnvironment = environment
        
        // Pre-fill with existing client_id if available
        if let clientId = credentialsManager.getClientId(for: environment) {
            editClientId = clientId
        } else {
            editClientId = ""
        }
        
        // Never pre-fill secret (user must enter new one)
        editClientSecret = ""
    }
    
    /// Cancel editing
    func cancelEditing() {
        editingEnvironment = nil
        editClientId = ""
        editClientSecret = ""
        errorMessage = nil
    }
    
    /// Save credentials for the currently editing environment
    func saveCredentials() {
        guard let environment = editingEnvironment else { return }
        
        // Validate inputs
        guard !editClientId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Client ID cannot be empty"
            return
        }
        
        guard !editClientSecret.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Client Secret cannot be empty"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Save to Keychain
            try credentialsManager.saveCredentials(
                clientId: editClientId.trimmingCharacters(in: .whitespacesAndNewlines),
                clientSecret: editClientSecret.trimmingCharacters(in: .whitespacesAndNewlines),
                for: environment
            )
            
            // Refresh the API service for this environment
            apiServiceManager.refreshService(for: environment)
            
            // Reload configuration status
            loadConfigurationStatus()
            
            // Show success message
            successMessage = "Credentials saved successfully for \(EnvironmentConfiguration.displayName(for: environment))"
            
            // Clear edit state
            editingEnvironment = nil
            editClientId = ""
            editClientSecret = ""
            
            isLoading = false
            
            // Clear success message after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.successMessage = nil
            }
            
        } catch {
            isLoading = false
            errorMessage = "Failed to save credentials: \(error.localizedDescription)"
        }
    }
    
    /// Delete credentials for an environment
    func deleteCredentials(for environment: OperatorEnvironment) {
        // Don't allow deleting default credentials (from Secrets.json)
        // Only allow deleting user-provided credentials (from Keychain)
        guard hasUserProvidedCredentials(for: environment) else {
            errorMessage = "Cannot delete default \(EnvironmentConfiguration.displayName(for: environment)) credentials. You can only replace them."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try credentialsManager.deleteCredentials(for: environment)
            
            // Refresh the API service for this environment
            apiServiceManager.refreshService(for: environment)
            
            // Reload configuration status
            loadConfigurationStatus()
            
            successMessage = "Credentials deleted for \(EnvironmentConfiguration.displayName(for: environment))"
            
            isLoading = false
            
            // Clear success message after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.successMessage = nil
            }
            
        } catch {
            isLoading = false
            errorMessage = "Failed to delete credentials: \(error.localizedDescription)"
        }
    }
    
    /// Get status icon for an environment
    func statusIcon(for environment: OperatorEnvironment) -> String {
        return isConfigured(environment: environment) ? "checkmark.circle.fill" : "xmark.circle.fill"
    }
    
    /// Get status color for an environment
    func statusColor(for environment: OperatorEnvironment) -> Color {
        return isConfigured(environment: environment) ? .green : .red
    }
}

