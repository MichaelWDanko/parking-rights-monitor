//
//  TokenTestView.swift
//  Passport API Explorer
//
//  Created by Michael Danko on 10/21/25.
//

import SwiftUI

struct TokenTestView: View {
    @State private var tokenResponse: TokenResponse?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @AppStorage("selectedThemeMode") private var selectedThemeMode: ThemeMode = .auto
    @Environment(\.colorScheme) var colorScheme

    @EnvironmentObject var apiServiceManager: APIServiceManager
    
    // Use production service for token testing
    private var passportAPIService: PassportAPIService? {
        apiServiceManager.service(for: .production)
    }

    var body: some View {
        Form {
            Section {
                Button(action: {
                    Task {
                        await fetchToken()
                    }
                }) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Text("Get Access Token")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(GlassmorphismButtonStyle(isPrimary: true))
                .disabled(isLoading)
            }
            .listRowBackground(Color.glassBackground)
            
            if let error = errorMessage {
                Section(header: Text("Error").foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))) {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                .listRowBackground(Color.glassBackground)
            }
            
            if let response = tokenResponse {
                Section(header: Text("Token Information").foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))) {
                    LabeledContent("Token Type", value: response.tokenType)
                        .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                    
                    if let expiresAt = response.formattedExpiresAt {
                        LabeledContent("Expires At", value: expiresAt)
                            .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                    }
                    
                    LabeledContent("Expires In", value: "\(response.expiresIn) seconds")
                        .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                }
                .listRowBackground(Color.glassBackground)
                
                if !response.scopesArray.isEmpty {
                    Section(header: Text("Scopes").foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))) {
                        ForEach(response.scopesArray, id: \.self) { scope in
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.caption)
                                Text(scope)
                                    .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                            }
                        }
                    }
                    .listRowBackground(Color.glassBackground)
                }
                
                Section(header: Text("Access Token").foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))) {
                    ScrollView {
                        Text(response.accessToken)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(minHeight: 100)
                    
                    Button(action: {
                        UIPasteboard.general.string = response.accessToken
                    }) {
                        Label("Copy Token", systemImage: "doc.on.doc")
                            .font(.caption)
                            .foregroundColor(Color.adaptiveCyanAccent(colorScheme == .dark))
                    }
                    .buttonStyle(.borderless)
                }
                .listRowBackground(Color.glassBackground)
            }
        }
        .scrollContentBackground(.hidden)
        .adaptiveGlassmorphismBackground()
        .navigationTitle("Token Test")
        .adaptiveGlassmorphismNavigation()
    }

    private func fetchToken() async {
        isLoading = true
        errorMessage = nil
        tokenResponse = nil
        
        guard let service = passportAPIService else {
            await MainActor.run {
                self.errorMessage = "Production environment not configured. Please add credentials in API Credentials settings."
                self.isLoading = false
            }
            return
        }
        
        do {
            let response = try await service.getTokenResponse()
            await MainActor.run {
                self.tokenResponse = response
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
}

#if DEBUG
struct TokenTestView_Previews: PreviewProvider {
    static var previews: some View {
        TokenTestView()
            .environmentObject(APIServiceManager(clientTraceId: "preview"))
    }
}
#endif
