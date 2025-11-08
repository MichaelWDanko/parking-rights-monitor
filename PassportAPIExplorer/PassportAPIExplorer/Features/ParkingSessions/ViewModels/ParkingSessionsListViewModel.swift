//
//  ParkingSessionsListViewModel.swift
//  Passport API Explorer
//
//  Created by Michael Danko on 10/30/25.
//

import Foundation
import SwiftData
import Observation

/// ViewModel managing the list of parking sessions stored locally in SwiftData.
/// Handles CRUD operations and CloudKit sync coordination (MVVM pattern).
/// Separates data access logic from the view layer.
@Observable
@MainActor
final class ParkingSessionsListViewModel {
    var sessions: [ParkingSession] = []
    var isLoading = false
    var errorMessage: String?
    var isSyncing = false
    
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadSessions()
    }
    
    // MARK: - Session Management
    
    /// Loads all parking sessions from SwiftData, sorted by creation date (newest first).
    /// SwiftData automatically syncs with CloudKit, so this includes synced data from other devices.
    func loadSessions() {
        do {
            let descriptor = FetchDescriptor<ParkingSession>(
                sortBy: [SortDescriptor(\.dateCreated, order: .reverse)]
            )
            sessions = try modelContext.fetch(descriptor)
        } catch {
            errorMessage = "Failed to load sessions: \(error.localizedDescription)"
        }
    }
    
    func createSession(
        sessionId: String? = nil,
        operatorId: String,
        zoneIdType: ZoneIDType,
        zoneId: String,
        zoneName: String? = nil,
        vehiclePlate: String,
        vehicleState: String,
        vehicleCountry: String,
        spaceNumber: String?,
        startTime: Date,
        endTime: Date
    ) {
        let session = ParkingSession(
            sessionId: sessionId,
            operatorId: operatorId,
            zoneIdType: zoneIdType,
            zoneId: zoneId,
            zoneName: zoneName,
            vehiclePlate: vehiclePlate,
            vehicleState: vehicleState,
            vehicleCountry: vehicleCountry,
            spaceNumber: spaceNumber,
            startTime: startTime,
            endTime: endTime
        )
        
        modelContext.insert(session)
        
        do {
            try modelContext.save()
            loadSessions()
        } catch {
            errorMessage = "Failed to save session: \(error.localizedDescription)"
        }
    }
    
    func deleteSession(_ session: ParkingSession) {
        modelContext.delete(session)
        
        do {
            try modelContext.save()
            loadSessions()
        } catch {
            errorMessage = "Failed to delete session: \(error.localizedDescription)"
        }
    }
    
    func updateSession(_ session: ParkingSession, newEndTime: Date) {
        session.endTime = newEndTime
        
        do {
            try modelContext.save()
            loadSessions()
        } catch {
            errorMessage = "Failed to update session: \(error.localizedDescription)"
        }
    }
    
    func stopSession(_ session: ParkingSession) {
        session.isActive = false
        
        do {
            try modelContext.save()
            loadSessions()
        } catch {
            errorMessage = "Failed to stop session: \(error.localizedDescription)"
        }
    }
    
    // MARK: - iCloud Sync
    
    /// Manually triggers CloudKit sync by saving pending changes and reloading data.
    /// CloudKit sync happens automatically, but this gives users control to force a refresh.
    /// The delay allows CloudKit time to process changes before reloading.
    func triggerSync() async {
        isSyncing = true
        print("🔄 [SYNC] ======== MANUAL SYNC TRIGGERED ========")
        print("📅 [SYNC] Time: \(Date())")
        print("🔍 [SYNC] Current sessions count: \(sessions.count)")
        
        defer { isSyncing = false }
        
        do {
            print("💾 [SYNC] Saving modelContext to push any pending changes...")
            // Save any pending changes to trigger CloudKit upload
            try modelContext.save()
            print("✅ [SYNC] ModelContext saved successfully")
            
            print("⏳ [SYNC] Waiting 2 seconds for CloudKit to process...")
            // NOTE: Task.sleep throws CancellationError if the task is cancelled (e.g. refresh ends)
            // Treat that as a benign cancellation and just return without surfacing an error.
            do { try await Task.sleep(nanoseconds: 2_000_000_000) } catch is CancellationError {
                print("⚠️ [SYNC] Sleep cancelled by system (pull-to-refresh). Treating as benign.")
                return
            }
            
            // Reload sessions to fetch any data synced from other devices
            loadSessions()
            
            print("✅ [SYNC] Sync completed at \(Date())")
            print("☁️ [SYNC] CloudKit should now be up to date")
            print("🔍 [SYNC] Final sessions count: \(sessions.count)")
            print("🔄 [SYNC] ======== SYNC COMPLETE ========")
        } catch is CancellationError {
            // Benign: the task was cancelled by the system; do not show an error toast
            print("⚠️ [SYNC] Sync task cancelled by system. Ignoring.")
        } catch {
            print("❌ [SYNC ERROR] Sync failed")
            print("❌ [SYNC ERROR] Details: \(error.localizedDescription)")
            errorMessage = "Sync failed: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Computed Properties
    
    var activeSessions: [ParkingSession] {
        let now = Date()
        return sessions.filter { $0.isActive && $0.endTime > now }
    }
}

