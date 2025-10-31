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
            print("🚀 [INIT] Starting ModelContainer initialization...")
            print("📅 [INIT] Device time: \(Date())")
            
            // Configure SwiftData with CloudKit support for Operator only
            // ParkingSession is stored locally only (not synced to iCloud)
            let schema = Schema([Operator.self, ParkingSession.self])
            print("📋 [SCHEMA] Registered models: Operator (synced), ParkingSession (local only)")
            
            let containerIdentifier = "iCloud.com.michaelwdanko.PassportAPIExplorer"
            
            // CloudKit configuration for Operator only
            let cloudKitConfiguration = ModelConfiguration(
                schema: Schema([Operator.self]),
                cloudKitDatabase: .private(containerIdentifier)
            )
            print("☁️ [CONFIG] CloudKit database: private(\(containerIdentifier))")
            print("🔄 [CONFIG] CloudKit sync enabled for: Operator")
            
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [cloudKitConfiguration]
            )
            
            print("✅ [SUCCESS] SwiftData with CloudKit configured successfully")
            print("🔄 [SYNC] CloudKit sync is ENABLED for Operators - records will sync across devices")
            print("📱 [CONTAINER] Using container: \(containerIdentifier)")
            print("💾 [LOCAL] ParkingSession data stored locally only (not synced)")
            print("🔍 [DEBUG] ModelContainer initialized with \(modelContainer.configurations.count) configuration(s)")
        } catch {
            print("❌ [ERROR] Failed to initialize ModelContainer")
            print("❌ [ERROR] Details: \(error)")
            print("❌ [ERROR] LocalizedDescription: \(error.localizedDescription)")
            if let nsError = error as NSError? {
                print("❌ [ERROR] Domain: \(nsError.domain)")
                print("❌ [ERROR] Code: \(nsError.code)")
                print("❌ [ERROR] UserInfo: \(nsError.userInfo)")
            }
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
