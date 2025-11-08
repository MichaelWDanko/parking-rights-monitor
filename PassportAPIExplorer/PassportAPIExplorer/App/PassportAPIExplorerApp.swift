//
//  PassportAPIExplorerApp.swift
//  Passport API Explorer
//
//  Created by Michael Danko on 10/4/25.
//

import SwiftUI
import SwiftData

/// Main app entry point. Initializes SwiftData with CloudKit sync and creates
/// the shared PassportAPIService instance for dependency injection.
@main
struct PassportAPIExplorerApp: App {
    
    let modelContainer: ModelContainer
    /// Shared API service instance injected into the view hierarchy via @EnvironmentObject
    private let passportAPIService: PassportAPIService
    
    init() {
        do {
            print("🚀 [INIT] Starting ModelContainer initialization...")
            print("📅 [INIT] Device time: \(Date())")
            
            // Configure SwiftData schema with models that sync to CloudKit
            // CloudKit sync enables data to sync across user's devices automatically
            let schema = Schema([Operator.self, ParkingSession.self])
            print("📋 [SCHEMA] Registered models: Operator, ParkingSession (both synced)")
            
            let containerIdentifier = "iCloud.com.michaelwdanko.PassportAPIExplorer"
            
            // Configure CloudKit private database for cross-device sync
            // Private database requires user authentication and is encrypted
            let cloudKitConfiguration = ModelConfiguration(
                schema: Schema([Operator.self, ParkingSession.self]),
                cloudKitDatabase: .private(containerIdentifier)
            )
            print("☁️ [CONFIG] CloudKit database: private(\(containerIdentifier))")
            print("🔄 [CONFIG] CloudKit sync enabled for: Operator, ParkingSession")
            
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [cloudKitConfiguration]
            )
            
            print("✅ [SUCCESS] SwiftData with CloudKit configured successfully")
            print("🔄 [SYNC] CloudKit sync is ENABLED for Operators and ParkingSessions - records will sync across devices")
            print("📱 [CONTAINER] Using container: \(containerIdentifier)")
            print("☁️ [SYNC] ParkingSession data now syncs to iCloud via CloudKit")
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
        // Initialize shared PassportAPIService singleton for dependency injection
        // This service handles all API communication and OAuth authentication
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

    var body: some Scene {
        WindowGroup {
            ContentView()
                // Inject PassportAPIService into the view hierarchy via @EnvironmentObject
                .environmentObject(passportAPIService)
        }
        // Provide SwiftData ModelContainer to all views via @Environment(\.modelContext)
        .modelContainer(modelContainer)
    }
}
