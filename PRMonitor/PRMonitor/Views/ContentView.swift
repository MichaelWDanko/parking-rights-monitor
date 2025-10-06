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
    
    var body: some View {

            
        TabView {
                    MonitorView()
                        .tabItem {
                            Label("Monitor", systemImage: "location.magnifyingglass")
                        }

                    SettingsView()
                        .tabItem {
                            Label("Settings", systemImage: "gearshape")
                        }
                }
    }

}

#Preview {
    ContentView()
}
