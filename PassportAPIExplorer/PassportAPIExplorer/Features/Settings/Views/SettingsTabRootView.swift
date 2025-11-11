//
//  SettingsTabRootView.swift
//  Passport API Explorer
//
//  Created by Michael Danko on 10/5/25.
//

import SwiftUI

struct SettingsTabRootView: View {
    @EnvironmentObject var apiServiceManager: APIServiceManager
    @AppStorage("selectedThemeMode") private var selectedThemeMode: ThemeMode = .auto
    @Environment(\.colorScheme) var colorScheme
    @State private var showingThemeSettings = false
    
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
                
                Section("Configuration") {
                    NavigationLink(destination: APICredentialsView(apiServiceManager: apiServiceManager)) {
                        HStack(spacing: 12) {
                            Image(systemName: "key.fill")
                                .foregroundColor(Color.adaptiveCyanAccent(colorScheme == .dark))
                                .font(.title3)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("API Credentials")
                                    .font(.headline)
                                    .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
                                Text("Manage credentials for each environment")
                                    .font(.caption)
                                    .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listRowBackground(Color.adaptiveGlassBackground(colorScheme == .dark))
                
                Section("Debug Tools") {
                    NavigationLink("Token Test", destination: TokenTestView())
                }
                .listRowBackground(Color.adaptiveGlassBackground(colorScheme == .dark))
                
                Section {
                    NavigationLink(destination: iCloudTestView()) {
                        HStack(spacing: 12) {
                            Image(systemName: "icloud.fill")
                                .foregroundColor(Color.adaptiveCyanAccent(colorScheme == .dark))
                                .font(.title3)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Data Sync")
                                    .font(.headline)
                                    .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
                                Text("Your sessions sync across all your devices")
                                    .font(.caption)
                                    .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                            }
                            
                            Spacer()
                            
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .symbolEffect(.pulse)
                        }
                        .padding(.vertical, 4)
                    }
                } footer: {
                    Text("Parking sessions and operators are automatically synced to your iCloud account. Make sure you're signed in to iCloud on all devices.")
                }
                .listRowBackground(Color.adaptiveGlassBackground(colorScheme == .dark))
                
                Section("About") {
                    HStack {
                        Text("Version")
                            .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
                        Spacer()
                        Text("2.0.0")
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
    // Create a mock service manager for preview
    let apiServiceManager = APIServiceManager(clientTraceId: "preview")
    
    return SettingsTabRootView()
        .environmentObject(apiServiceManager)
}
