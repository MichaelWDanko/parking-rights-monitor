//
//  APICredentialsView.swift
//  Passport API Explorer
//
//  Created by Michael Danko on 11/11/25.
//

import SwiftUI

struct APICredentialsView: View {
    @State private var viewModel: APICredentialsViewModel
    @Environment(\.colorScheme) var colorScheme
    @State private var showingDeleteConfirmation = false
    @State private var environmentToDelete: OperatorEnvironment?
    
    init(apiServiceManager: APIServiceManager) {
        _viewModel = State(initialValue: APICredentialsViewModel(apiServiceManager: apiServiceManager))
    }
    
    var body: some View {
        List {
            // Info Section
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                        Text("About API Credentials")
                            .font(.headline)
                            .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
                    }
                    
                    Text("Default credentials for all environments are shipped with the app. You can replace them with your own credentials if needed.")
                        .font(.subheadline)
                        .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text("Credentials are stored securely on your device and never synced to iCloud.")
                        .font(.caption)
                        .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 4)
            }
            .listRowBackground(Color.adaptiveGlassBackground(colorScheme == .dark))
            
            // Success/Error Messages
            if let successMessage = viewModel.successMessage {
                Section {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(successMessage)
                            .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
                    }
                }
                .listRowBackground(Color.green.opacity(0.1))
            }
            
            if let errorMessage = viewModel.errorMessage {
                Section {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .listRowBackground(Color.red.opacity(0.1))
            }
            
            // Environments
            ForEach(OperatorEnvironment.allCases, id: \.self) { environment in
                Section(header: Text(EnvironmentConfiguration.displayName(for: environment))) {
                    environmentRow(for: environment)
                }
                .listRowBackground(Color.adaptiveGlassBackground(colorScheme == .dark))
            }
        }
        .scrollContentBackground(.hidden)
        .navigationTitle("API Credentials")
        .adaptiveGlassmorphismNavigation()
        .adaptiveGlassmorphismBackground()
        .sheet(item: Binding(
            get: { viewModel.editingEnvironment },
            set: { viewModel.editingEnvironment = $0 }
        )) { environment in
            editCredentialsSheet(for: environment)
        }
        .alert("Delete Credentials", isPresented: $showingDeleteConfirmation, presenting: environmentToDelete) { environment in
            Button("Cancel", role: .cancel) {
                environmentToDelete = nil
            }
            Button("Delete", role: .destructive) {
                viewModel.deleteCredentials(for: environment)
                environmentToDelete = nil
            }
        } message: { environment in
            Text("Are you sure you want to delete the credentials for \(EnvironmentConfiguration.displayName(for: environment))? This cannot be undone.")
        }
    }
    
    @ViewBuilder
    private func environmentRow(for environment: OperatorEnvironment) -> some View {
        VStack(spacing: 12) {
            // Status Row
            HStack {
                Image(systemName: viewModel.statusIcon(for: environment))
                    .foregroundColor(viewModel.statusColor(for: environment))
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Status")
                        .font(.caption)
                        .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                    Text(viewModel.isConfigured(environment: environment) ? "Configured" : "Not Configured")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
                }
                
                Spacer()
            }
            
            // Client ID Row
            VStack(alignment: .leading, spacing: 4) {
                Text("Client ID")
                    .font(.caption)
                    .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                
                HStack {
                    Text(viewModel.getClientId(for: environment))
                        .font(.system(.subheadline, design: .monospaced))
                        .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
                        .textSelection(.enabled)
                    
                    Spacer()
                    
                    if viewModel.isConfigured(environment: environment) {
                        Button(action: {
                            UIPasteboard.general.string = viewModel.getClientId(for: environment)
                        }) {
                            Image(systemName: "doc.on.doc")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            // Client Secret Row
            VStack(alignment: .leading, spacing: 4) {
                Text("Client Secret")
                    .font(.caption)
                    .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                
                Text(viewModel.getMaskedSecret(for: environment))
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
            }
            
            // Action Buttons
            HStack(spacing: 12) {
                Button(action: {
                    viewModel.startEditing(environment: environment)
                }) {
                    HStack {
                        Image(systemName: viewModel.isConfigured(environment: environment) ? "pencil" : "plus")
                        Text(viewModel.isConfigured(environment: environment) ? "Update" : "Add")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.blue)
                
                if viewModel.hasUserProvidedCredentials(for: environment) {
                    Button(action: {
                        environmentToDelete = environment
                        showingDeleteConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }
            }
            
            // Special note for default credentials
            if !viewModel.hasUserProvidedCredentials(for: environment) && viewModel.isConfigured(environment: environment) {
                Text("Using default credentials from app bundle")
                    .font(.caption2)
                    .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                    .italic()
            }
        }
        .padding(.vertical, 4)
    }
    
    @ViewBuilder
    private func editCredentialsSheet(for environment: OperatorEnvironment) -> some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Configure credentials for \(EnvironmentConfiguration.displayName(for: environment))")
                            .font(.subheadline)
                            .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                        
                        if !viewModel.hasUserProvidedCredentials(for: environment) && viewModel.isConfigured(environment: environment) {
                            Text("Note: This will replace the default \(EnvironmentConfiguration.displayName(for: environment)) credentials shipped with the app.")
                                .font(.caption)
                                .foregroundColor(.orange)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                
                Section("Client ID") {
                    TextField("Enter Client ID", text: $viewModel.editClientId)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .font(.system(.body, design: .monospaced))
                }
                
                Section("Client Secret") {
                    SecureField("Enter Client Secret", text: $viewModel.editClientSecret)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .font(.system(.body, design: .monospaced))
                    
                    Text("Secret is never displayed after saving")
                        .font(.caption)
                        .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                }
                
                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Edit Credentials")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.cancelEditing()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.saveCredentials()
                    }
                    .disabled(viewModel.editClientId.isEmpty || viewModel.editClientSecret.isEmpty)
                }
            }
            .disabled(viewModel.isLoading)
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.2))
                }
            }
        }
    }
}

// Make OperatorEnvironment identifiable for sheet presentation
extension OperatorEnvironment: Identifiable {
    var id: String { rawValue }
}

#Preview {
    let apiServiceManager = APIServiceManager()
    NavigationStack {
        APICredentialsView(apiServiceManager: apiServiceManager)
    }
}

