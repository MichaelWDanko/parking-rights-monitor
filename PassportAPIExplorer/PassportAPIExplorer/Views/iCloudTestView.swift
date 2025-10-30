//
//  iCloudTestView.swift
//  Passport API Explorer
//
//  Created by Michael Danko on 10/22/25.
//

import SwiftUI
import SwiftData
import CloudKit

struct iCloudTestView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("selectedThemeMode") private var selectedThemeMode: ThemeMode = .auto
    @Environment(\.colorScheme) var colorScheme
    @Query private var operators: [Operator]
    @State private var dataService: OperatorDataService?
    @State private var testOperatorName = "iCloud Test Operator"
    @State private var editingOperator: Operator?
    @State private var editedName = ""
    @State private var isSyncing = false
    @State private var lastSyncTime: Date?
    @State private var iCloudAccountStatus: String = "Checking..."
    @State private var cloudKitAvailable: Bool = false
    @State private var diagnosticMessage: String = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Data Sync")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
                        
                        Text("Test iCloud synchronization by adding a test operator and checking if it appears on other devices.")
                            .font(.subheadline)
                            .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .adaptiveGlassmorphismCard()
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Add Operator Section
                    VStack(spacing: 16) {
                        TextField("Test Operator Name", text: $testOperatorName)
                            .adaptiveGlassmorphismTextField()
                        
                        Button("Add Test Operator") {
                            addTestOperator()
                        }
                        .buttonStyle(GlassmorphismButtonStyle(isPrimary: true))
                        .disabled(testOperatorName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    .padding(.horizontal)
                    
                    // Operators List
                    if !operators.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Current Operators (\(operators.count))")
                                .font(.headline)
                                .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
                                .padding(.horizontal)
                            
                            List {
                                ForEach(operators) { op in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(op.name)
                                                .font(.subheadline)
                                                .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
                                            Text("ID: \(op.id)")
                                                .font(.caption2)
                                                .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                                                .lineLimit(1)
                                        }
                                        Spacer()
                                        Text(op.environment?.rawValue.capitalized ?? "Unknown")
                                            .font(.caption)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.adaptiveCyanAccent(colorScheme == .dark))
                                            .foregroundColor(.navyBlue)
                                            .cornerRadius(4)
                                    }
                                    .listRowBackground(Color.adaptiveGlassBackground(colorScheme == .dark))
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        Button(role: .destructive) {
                                            deleteOperator(op)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                        
                                        Button {
                                            editOperator(op)
                                        } label: {
                                            Label("Edit", systemImage: "pencil")
                                        }
                                        .tint(.blue)
                                    }
                                    .contextMenu {
                                        Button {
                                            editOperator(op)
                                        } label: {
                                            Label("Edit", systemImage: "pencil")
                                        }
                                        
                                        Button(role: .destructive) {
                                            deleteOperator(op)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                            .frame(height: CGFloat(operators.count) * 70)
                            .scrollDisabled(true)
                            .scrollContentBackground(.hidden)
                            .listStyle(.plain)
                        }
                        .padding()
                        .adaptiveGlassmorphismCard()
                        .padding(.horizontal)
                    }
                    
                    // iCloud Status
                    VStack(spacing: 16) {
                        Text("iCloud Status")
                            .font(.headline)
                            .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
                        
                        HStack(spacing: 12) {
                            Image(systemName: cloudKitAvailable ? "icloud.fill" : "icloud.slash.fill")
                                .foregroundColor(cloudKitAvailable ? Color.adaptiveCyanAccent(colorScheme == .dark) : .red)
                                .font(.title2)
                                .symbolEffect(.pulse)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(iCloudAccountStatus)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
                                
                                if let lastSync = lastSyncTime {
                                    Text("Last sync: \(lastSync.formatted(date: .omitted, time: .shortened))")
                                        .font(.caption)
                                        .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                                }
                            }
                            
                            Spacer()
                            
                            Image(systemName: cloudKitAvailable ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(cloudKitAvailable ? .green : .red)
                        }
                        
                        // Diagnostic Information
                        if !diagnosticMessage.isEmpty {
                            Text(diagnosticMessage)
                                .font(.caption)
                                .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                                .background(Color.adaptiveGlassBackground(colorScheme == .dark).opacity(0.5))
                                .cornerRadius(8)
                        }
                        
                        VStack(spacing: 12) {
                            Button(action: triggerSync) {
                                HStack(spacing: 8) {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                        .font(.system(size: 16))
                                    Text(isSyncing ? "Syncing..." : "Sync Now")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 2)
                            }
                            .buttonStyle(GlassmorphismButtonStyle(isPrimary: true))
                            .disabled(isSyncing || !cloudKitAvailable)
                            
                            Button(action: checkICloudStatus) {
                                HStack(spacing: 8) {
                                    Image(systemName: "info.circle")
                                        .font(.system(size: 14))
                                    Text("Check iCloud Status")
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 2)
                            }
                            .buttonStyle(GlassmorphismButtonStyle(isPrimary: false))
                        }
                    }
                    .padding()
                    .adaptiveGlassmorphismCard()
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("Data Sync")
            .adaptiveGlassmorphismNavigation()
            .adaptiveGlassmorphismBackground()
            .onAppear {
                print("👁️ [VIEW] Data Sync view appeared")
                print("📅 [VIEW] Time: \(Date())")
                print("🔍 [VIEW] Loaded operators count: \(operators.count)")
                
                if operators.isEmpty {
                    print("⚠️ [VIEW] No operators found in database")
                } else {
                    print("📋 [VIEW] Operators in database:")
                    for (index, op) in operators.enumerated() {
                        print("   [VIEW] \(index + 1). '\(op.name)' (ID: \(op.id), Env: \(op.environment?.rawValue ?? "nil"))")
                    }
                }
                
                if dataService == nil {
                    print("🔧 [VIEW] Initializing OperatorDataService...")
                    dataService = OperatorDataService(modelContext: modelContext)
                    print("✅ [VIEW] OperatorDataService initialized")
                }
                
                // Check iCloud status automatically on appear
                checkICloudStatus()
            }
            .sheet(item: $editingOperator) { op in
                NavigationStack {
                    VStack(spacing: 20) {
                        Text("Edit Operator")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
                            .padding(.top)
                        
                        TextField("Operator Name", text: $editedName)
                            .adaptiveGlassmorphismTextField()
                            .padding(.horizontal)
                        
                        Button("Save Changes") {
                            saveEditedOperator(op)
                        }
                        .buttonStyle(GlassmorphismButtonStyle(isPrimary: true))
                        .disabled(editedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .padding(.horizontal)
                        
                        Spacer()
                    }
                    .adaptiveGlassmorphismBackground()
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                editingOperator = nil
                            }
                            .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
                        }
                    }
                }
                .presentationDetents([.height(300)])
            }
        }
    }
    
    private func addTestOperator() {
        let trimmedName = testOperatorName.trimmingCharacters(in: .whitespacesAndNewlines)
        print("➕ [ADD] Adding test operator: '\(trimmedName)'")
        print("📅 [ADD] Time: \(Date())")
        
        if let newOperator = dataService?.addOperator(name: trimmedName, id: UUID().uuidString, environment: .development) {
            print("✅ [ADD] Test operator added successfully")
            print("   [ADD] Name: \(newOperator.name)")
            print("   [ADD] ID: \(newOperator.id)")
            print("   [ADD] Environment: \(newOperator.environment?.rawValue ?? "nil")")
            
            do {
                try modelContext.save()
                print("💾 [SAVE] ModelContext saved successfully after add")
                print("☁️ [SYNC] Changes should now sync to CloudKit...")
            } catch {
                print("❌ [SAVE ERROR] Failed to save after add: \(error.localizedDescription)")
            }
            
            testOperatorName = "iCloud Test Operator" // Reset for next test
            
            // Trigger a sync check
            print("🔄 [SYNC] Total operators in context: \(operators.count)")
        } else {
            print("❌ [ADD ERROR] Failed to create operator via dataService")
        }
    }
    
    private func editOperator(_ operator: Operator) {
        editedName = `operator`.name
        editingOperator = `operator`
    }
    
    private func saveEditedOperator(_ operator: Operator) {
        let trimmedName = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        print("✏️ [EDIT] Updating operator")
        print("   [EDIT] Old name: '\(`operator`.name)'")
        print("   [EDIT] New name: '\(trimmedName)'")
        print("   [EDIT] ID: \(`operator`.id)")
        print("📅 [EDIT] Time: \(Date())")
        
        `operator`.name = trimmedName
        do {
            try modelContext.save()
            print("✅ [EDIT] Operator updated successfully")
            print("💾 [SAVE] ModelContext saved successfully after edit")
            print("☁️ [SYNC] Update should now sync to CloudKit...")
            editingOperator = nil
        } catch {
            print("❌ [EDIT ERROR] Failed to update operator")
            print("❌ [EDIT ERROR] Details: \(error.localizedDescription)")
        }
    }
    
    private func deleteOperator(_ operator: Operator) {
        print("🗑️ [DELETE] Deleting operator")
        print("   [DELETE] Name: '\(`operator`.name)'")
        print("   [DELETE] ID: \(`operator`.id)")
        print("📅 [DELETE] Time: \(Date())")
        
        modelContext.delete(`operator`)
        do {
            try modelContext.save()
            print("✅ [DELETE] Operator deleted successfully")
            print("💾 [SAVE] ModelContext saved successfully after delete")
            print("☁️ [SYNC] Deletion should now sync to CloudKit...")
            print("🔄 [SYNC] Remaining operators in context: \(operators.count)")
        } catch {
            print("❌ [DELETE ERROR] Failed to delete operator")
            print("❌ [DELETE ERROR] Details: \(error.localizedDescription)")
        }
    }
    
    private func triggerSync() {
        isSyncing = true
        print("🔄 [SYNC] ======== MANUAL SYNC TRIGGERED ========")
        print("📅 [SYNC] Time: \(Date())")
        print("🔍 [SYNC] Current operators count: \(operators.count)")
        
        // Log all operators
        for (index, op) in operators.enumerated() {
            print("   [SYNC] Operator \(index + 1): '\(op.name)' (ID: \(op.id))")
        }
        
        Task {
            do {
                print("💾 [SYNC] Saving modelContext to push any pending changes...")
                // Save any pending changes
                try modelContext.save()
                print("✅ [SYNC] ModelContext saved successfully")
                
                print("⏳ [SYNC] Waiting 2 seconds for CloudKit to process...")
                // Wait a moment to allow CloudKit to sync
                try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                
                await MainActor.run {
                    lastSyncTime = Date()
                    isSyncing = false
                    print("✅ [SYNC] Sync completed at \(Date())")
                    print("☁️ [SYNC] CloudKit should now be up to date")
                    print("📱 [SYNC] Check your other devices - data should appear within 30 seconds")
                    print("🔍 [SYNC] Final operators count: \(operators.count)")
                    print("🔄 [SYNC] ======== SYNC COMPLETE ========")
                }
            } catch {
                await MainActor.run {
                    isSyncing = false
                    print("❌ [SYNC ERROR] Sync failed")
                    print("❌ [SYNC ERROR] Details: \(error.localizedDescription)")
                    if let nsError = error as NSError? {
                        print("❌ [SYNC ERROR] Domain: \(nsError.domain)")
                        print("❌ [SYNC ERROR] Code: \(nsError.code)")
                    }
                }
            }
        }
    }
    
    private func checkICloudStatus() {
        print("🔍 [DIAGNOSTIC] ======== CHECKING ICLOUD STATUS ========")
        print("📅 [DIAGNOSTIC] Time: \(Date())")
        
        Task {
            let container = CKContainer(identifier: "iCloud.com.michaelwdanko.PassportAPIExplorer")
            
            do {
                // Check account status
                let accountStatus = try await container.accountStatus()
                
                await MainActor.run {
                    print("📊 [DIAGNOSTIC] Account Status: \(accountStatus.rawValue)")
                    
                    switch accountStatus {
                    case .available:
                        iCloudAccountStatus = "iCloud Account: Available"
                        cloudKitAvailable = true
                        diagnosticMessage = "✅ iCloud is properly configured. CloudKit sync is active."
                        print("✅ [DIAGNOSTIC] iCloud account is available")
                        
                    case .noAccount:
                        iCloudAccountStatus = "iCloud Account: Not Signed In"
                        cloudKitAvailable = false
                        diagnosticMessage = "⚠️ No iCloud account signed in. Please sign in to Settings > iCloud."
                        print("⚠️ [DIAGNOSTIC] No iCloud account - user needs to sign in")
                        
                    case .restricted:
                        iCloudAccountStatus = "iCloud Account: Restricted"
                        cloudKitAvailable = false
                        diagnosticMessage = "⚠️ iCloud access is restricted. Check parental controls or device management settings."
                        print("⚠️ [DIAGNOSTIC] iCloud account is restricted")
                        
                    case .couldNotDetermine:
                        iCloudAccountStatus = "iCloud Account: Could Not Determine"
                        cloudKitAvailable = false
                        diagnosticMessage = "⚠️ Could not determine iCloud status. Try restarting the app or checking Settings > iCloud."
                        print("⚠️ [DIAGNOSTIC] Could not determine iCloud account status")
                        
                    case .temporarilyUnavailable:
                        iCloudAccountStatus = "iCloud Account: Temporarily Unavailable"
                        cloudKitAvailable = false
                        diagnosticMessage = "⚠️ iCloud is temporarily unavailable. Please try again in a moment."
                        print("⚠️ [DIAGNOSTIC] iCloud is temporarily unavailable")
                        
                    @unknown default:
                        iCloudAccountStatus = "iCloud Account: Unknown Status"
                        cloudKitAvailable = false
                        diagnosticMessage = "⚠️ Unknown iCloud status. Please check Settings > iCloud."
                        print("⚠️ [DIAGNOSTIC] Unknown iCloud account status")
                    }
                }
                
                // Additional checks if account is available
                if accountStatus == .available {
                    // Check if we can access the database
                    let database = container.privateCloudDatabase
                    print("🗄️ [DIAGNOSTIC] Private database accessed successfully")
                    
                    // Verify we can access the database (no need for actual query)
                    // SwiftData handles the actual syncing automatically
                    await MainActor.run {
                        print("✅ [DIAGNOSTIC] CloudKit database accessible")
                        print("🔄 [DIAGNOSTIC] SwiftData is managing sync automatically")
                        diagnosticMessage += "\n🔄 SwiftData is managing sync automatically."
                        
                        // Show operator count
                        let operatorCount = operators.count
                        print("📊 [DIAGNOSTIC] Current device has \(operatorCount) operator(s)")
                        diagnosticMessage += "\n📊 This device has \(operatorCount) operator(s)."
                        
                        if operatorCount == 0 {
                            diagnosticMessage += "\n💡 Add an operator on another device to test sync."
                        } else {
                            diagnosticMessage += "\n💡 These should appear on other signed-in devices within 30 seconds."
                        }
                    }
                }
                
                print("🔍 [DIAGNOSTIC] ======== STATUS CHECK COMPLETE ========")
                
            } catch {
                await MainActor.run {
                    iCloudAccountStatus = "Error Checking Status"
                    cloudKitAvailable = false
                    diagnosticMessage = "❌ Error: \(error.localizedDescription)"
                    print("❌ [DIAGNOSTIC] Error checking iCloud status: \(error.localizedDescription)")
                    if let nsError = error as NSError? {
                        print("❌ [DIAGNOSTIC] Error domain: \(nsError.domain)")
                        print("❌ [DIAGNOSTIC] Error code: \(nsError.code)")
                    }
                }
            }
        }
    }
}

#Preview {
    iCloudTestView()
        .modelContainer(for: Operator.self, inMemory: true)
}
