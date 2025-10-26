//
//  SettingsTabRootView.swift
//  Passport API Explorer
//
//  Created by Michael Danko on 10/5/25.
//

import SwiftUI

struct SettingsTabRootView: View {
    let passportAPIService: PassportAPIService
    @AppStorage("selectedThemeMode") private var selectedThemeMode: ThemeMode = .auto
    @Environment(\.colorScheme) var colorScheme
    @State private var showingThemeSettings = false
    
    init(passportAPIService: PassportAPIService) {
        self.passportAPIService = passportAPIService
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section("Appearance") {
                    Button(action: {
                        showingThemeSettings = true
                    }) {
                        HStack {
                            Text("Theme")
                            Spacer()
                            Text(selectedThemeMode.displayName)
                                .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                            Image(systemName: "chevron.right")
                                .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                        }
                    }
                    .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
                }
                .listRowBackground(Color.adaptiveGlassBackground(colorScheme == .dark))
                
                Section("Debug Tools") {
                    NavigationLink("Token Test", destination: TokenTestView(passportAPIService: passportAPIService))
                    NavigationLink("iCloud Test", destination: iCloudTestView())
                }
                .listRowBackground(Color.adaptiveGlassBackground(colorScheme == .dark))
                
                Section("About") {
                    HStack {
                        Text("Version")
                            .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                    }
                }
                .listRowBackground(Color.adaptiveGlassBackground(colorScheme == .dark))
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("Settings")
            .adaptiveGlassmorphismNavigation()
            .adaptiveGlassmorphismBackground()
            .sheet(isPresented: $showingThemeSettings) {
                ThemeSettingsView()
            }
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
