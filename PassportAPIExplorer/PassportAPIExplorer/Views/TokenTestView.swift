//
//  TokenTestView.swift
//  Passport API Explorer
//
//  Created by Michael Danko on 10/21/25.
//

import SwiftUI

struct TokenTestView: View {
    @State private var token: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    let passportAPIService: PassportAPIService

    var body: some View {
        VStack(spacing: 20) {
            Text("Token Test")
                .font(.title)
                .foregroundColor(.glassTextPrimary)
            
            Button("Get Access Token") {
                Task {
                    await fetchToken()
                }
            }
            .disabled(isLoading)
            .buttonStyle(GlassmorphismButtonStyle(isPrimary: true))
            
            if isLoading {
                ProgressView("Loading token...")
                    .foregroundColor(.glassTextPrimary)
            }
            
            if let error = errorMessage {
                VStack(spacing: 8) {
                    Text("Error: \(error)")
                        .foregroundColor(.cyanAccent)
                        .padding()
                }
                .glassmorphismCard()
                .padding()
            }
            
            if !token.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Token:")
                        .font(.headline)
                        .foregroundColor(.glassTextPrimary)
                    Text(token)
                        .font(.caption)
                        .foregroundColor(.glassTextSecondary)
                        .padding()
                        .glassmorphismCard()
                }
                .padding()
            }
        }
        .padding()
        .glassmorphismBackground()
        .navigationTitle("Token Test")
        .glassmorphismNavigation()
    }

    private func fetchToken() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let token = try await passportAPIService.getValidToken()
            await MainActor.run {
                self.token = token
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
        TokenTestView(passportAPIService: PassportAPIService(config: OAuthConfiguration(
            tokenURL: URL(string: "https://example.com/token")!,
            client_id: "test",
            client_secret: "test",
            audience: "test",
            clientTraceId: "preview"
        )))
    }
}
#endif
