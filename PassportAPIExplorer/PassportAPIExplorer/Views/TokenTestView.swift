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
            
            Button("Get Access Token") {
                Task {
                    await fetchToken()
                }
            }
            .disabled(isLoading)
            
            if isLoading {
                ProgressView("Loading token...")
            }
            
            if let error = errorMessage {
                Text("Error: \(error)")
                    .foregroundColor(.red)
                    .padding()
            }
            
            if !token.isEmpty {
                VStack(alignment: .leading) {
                    Text("Token:")
                        .font(.headline)
                    Text(token)
                        .font(.caption)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
        .padding()
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
