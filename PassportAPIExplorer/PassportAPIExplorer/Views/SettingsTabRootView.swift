//
//  SettingsTabRootView.swift
//  Passport API Explorer
//
//  Created by Michael Danko on 10/5/25.
//

import SwiftUI

struct SettingsTabRootView: View {
    let passportAPIService: PassportAPIService
    
    init(passportAPIService: PassportAPIService) {
        self.passportAPIService = passportAPIService
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section("Debug Tools") {
                    NavigationLink("Token Test", destination: TokenTestView(passportAPIService: passportAPIService))
                    NavigationLink("iCloud Test", destination: iCloudTestView())
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    // Create a mock service for preview
    let config = OAuthConfiguration(
        tokenURL: URL(string: "https://api.us.passportinc.com/v3/shared/access-tokens")!,
        client_id: "test",
        client_secret: "test",
        audience: "public.api.passportinc.com",
        clientTraceId: "preview"
    )
    let passportAPIService = PassportAPIService(config: config)
    
    return SettingsTabRootView(passportAPIService: passportAPIService)
}
