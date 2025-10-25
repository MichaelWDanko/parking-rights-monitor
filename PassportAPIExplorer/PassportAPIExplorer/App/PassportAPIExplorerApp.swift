//
//  PassportAPIExplorerApp.swift
//  Passport API Explorer
//
//  Created by Michael Danko on 10/4/25.
//

import SwiftUI
import SwiftData

@main
struct PassportAPIExplorerApp: App {
    
    let modelContainer: ModelContainer
    
    init() {
        do {
            // Configure SwiftData with CloudKit support
            let schema = Schema([Operator.self])
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                cloudKitDatabase: .private("iCloud.com.michaelwdanko.PassportAPIExplorer")
            )
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
            
            print("✅ SwiftData with CloudKit configured successfully")
            print("📱 CloudKit Container: iCloud.com.michaelwdanko.PassportAPIExplorer")
            print("☁️ CloudKit sync is enabled - records will sync across devices")
        } catch {
            print("❌ Failed to initialize ModelContainer: \(error)")
            print("💡 This is likely due to schema changes. Please delete the app and reinstall to clear old data.")
            fatalError("Could not initialize ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}
