//
//  ContentView.swift
//  Passport API Explorer
//
//  Created by Michael Danko on 10/4/25.
//

import SwiftUI
import SwiftData

/// Root content view with tab navigation.
/// Provides access to PassportAPIService via @EnvironmentObject (dependency injection).
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selection: String? = nil
    @AppStorage("selectedThemeMode") private var selectedThemeMode: ThemeMode = .auto
    /// Injected API service from PassportAPIExplorerApp (dependency injection pattern)
    @EnvironmentObject var passportAPIService: PassportAPIService

    var body: some View {
        TabView {
            NavigationStack{
                OperatorSelectionView()
            }
            .tabItem {
                Label("Parking Rights", systemImage: "network")
            }
            
            NavigationStack{
                ParkingSessionEventView()
            }
            .tabItem {
                Label("Parking Sessions", systemImage: "paperplane.fill")
            }
            
            NavigationStack{
                SettingsTabRootView()
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
        .environmentObject(PreviewEnvironment.makePreviewService())
        .modelContainer(for: Operator.self, inMemory: true)
}
