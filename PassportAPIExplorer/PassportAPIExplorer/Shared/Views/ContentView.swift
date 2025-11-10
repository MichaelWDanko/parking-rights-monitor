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
    @Environment(\.colorScheme) var colorScheme
    @State private var selection: String? = nil
    @AppStorage("selectedThemeMode") private var selectedThemeMode: ThemeMode = .auto
    /// Injected API service from PassportAPIExplorerApp (dependency injection pattern)
    @EnvironmentObject var passportAPIService: PassportAPIService
    /// Drawer view model for operator selection
    @StateObject private var drawerViewModel = OperatorDrawerViewModel()

    var body: some View {
        TabView {
            Group {
                if UIDevice.current.userInterfaceIdiom == .phone {
                    // iPhone: Custom Drawer
                    OperatorDrawer(viewModel: drawerViewModel) {
                        NavigationStack {
                            if let selectedOperator = drawerViewModel.selectedOperator {
                                OperatorZoneView(selectedOperator: selectedOperator)
                            } else {
                                // Empty view that auto-opens drawer
                                Color.clear
                                    .adaptiveGlassmorphismBackground()
                                    .onAppear {
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                            drawerViewModel.openDrawer()
                                        }
                                    }
                            }
                        }
                    }
                    .environmentObject(drawerViewModel)
                } else {
                    // iPad/Mac: NavigationSplitView
                    NavigationSplitView {
                        OperatorSelectionView()
                    } detail: {
                        if let selectedOperator = drawerViewModel.selectedOperator {
                            OperatorZoneView(selectedOperator: selectedOperator)
                        } else {
                            VStack(spacing: 20) {
                                Image(systemName: "building.2")
                                    .font(.system(size: 50))
                                    .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                                
                                Text("Select an operator")
                                    .font(.headline)
                                    .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .adaptiveGlassmorphismBackground()
                        }
                    }
                    .environmentObject(drawerViewModel)
                }
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
