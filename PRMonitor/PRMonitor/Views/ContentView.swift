//
//  ContentView.swift
//  PRMonitor
//
//  Created by Michael Danko on 10/4/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selection: String? = nil
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
                MonitorTabRootView()
            }
            .tabItem {
                Label("Monitor", systemImage: "location.magnifyingglass")
            }
            
            NavigationStack{
                SettingsTabRootView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
            
            NavigationStack{
                TokenTestView(passportAPIService: passportAPIService)
            }
            .tabItem {
                Label("Token Test", systemImage: "gearshift.layout.sixspeed")
            }
        }
    }
}

#Preview {
    ContentView()
}
