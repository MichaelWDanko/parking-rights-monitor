//
//  ContentView.swift
//  Passport API Explorer
//
//  Created by Michael Danko on 10/4/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selection: String? = nil
    @AppStorage("selectedThemeMode") private var selectedThemeMode: ThemeMode = .auto
    let passportAPIService: PassportAPIService

    init() {
        // Load secrets/config and create the shared Passport API service once
        let secrets = try! SecretsLoader.load()
        let config = OAuthConfiguration(
            tokenURL: URL(string: "https://api.us.passportinc.com/v3/shared/access-tokens")!,
            client_id: secrets.client_id,
            client_secret: secrets.client_secret,
            audience: "public.api.passportinc.com",
            clientTraceId: "danko-test"
        )
        self.passportAPIService = PassportAPIService(config: config)
    }

    var body: some View {
        TabView {
            NavigationStack{
                OperatorSelectionView()
            }
            .tabItem {
                Label("API Explorer", systemImage: "network")
            }
            .environmentObject(passportAPIService)
            
            NavigationStack{
                SettingsTabRootView(passportAPIService: passportAPIService)
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
        }
        .adaptiveGlassmorphismTabView()
        .preferredColorScheme(selectedThemeMode.preferredColorScheme)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Operator.self, inMemory: true)
}
