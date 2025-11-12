//
//  OperatorDataService.swift
//  Passport API Explorer
//
//  Created by Michael Danko on 10/22/25.
//

import Foundation
import SwiftData

/// Service class for managing Operator data persistence.
/// Provides CRUD operations for operators stored in SwiftData/CloudKit.
/// Separates data access logic from ViewModels (service layer pattern).
@Observable
class OperatorDataService {
    private var modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - CRUD Operations
    
    /// Fetches all operators from SwiftData, sorted by name.
    /// Returns empty array on error (graceful degradation).
    func fetchOperators() -> [Operator] {
        let descriptor = FetchDescriptor<Operator>(
            sortBy: [SortDescriptor(\.name)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching operators: \(error)")
            return []
        }
    }
    
    /// Creates and saves a new operator to SwiftData.
    /// Changes automatically sync to CloudKit (no manual sync needed).
    func addOperator(name: String, id: String? = nil, environment: OperatorEnvironment = .production) -> Operator? {
        let newOperator = Operator(name: name, id: id, environment: environment)
        
        do {
            modelContext.insert(newOperator)
            try modelContext.save()
            print("✅ Successfully added operator: \(newOperator.name) (ID: \(newOperator.id))")
            print("☁️ Operator will sync to iCloud automatically")
            return newOperator
        } catch {
            print("❌ Error adding operator: \(error)")
            return nil
        }
    }
    
    func updateOperator(_ op: Operator, name: String, id: String, environment: OperatorEnvironment) {
        op.name = name
        op.id = id
        op.environment = environment
        
        do {
            try modelContext.save()
            print("✅ Successfully updated operator: \(op.name) (ID: \(op.id))")
            print("☁️ Changes will sync to iCloud automatically")
        } catch {
            print("❌ Error updating operator: \(error)")
        }
    }
    
    func deleteOperator(_ op: Operator) {
        do {
            let operatorName = op.name
            let operatorId = op.id
            modelContext.delete(op)
            try modelContext.save()
            print("✅ Successfully deleted operator: \(operatorName) (ID: \(operatorId))")
            print("☁️ Deletion will sync to iCloud automatically")
        } catch {
            print("❌ Error deleting operator: \(error)")
        }
    }
    
    // MARK: - Migration from Mock Data
    
    func migrateFromMockDataIfNeeded() {
        let existingOperators = fetchOperators()
        
        // Only migrate if no operators exist
        if existingOperators.isEmpty {
            print("🔄 [MIGRATION] No operators found, creating default operators for all environments...")
            
            // Create default operators for each environment
            let defaultOperators = [
                Operator(
                    name: "zDanko Parking",
                    id: "43c401c0-a17e-40e5-ae26-4f5f205bf063",
                    environment: .production
                ),
                Operator(
                    name: "zDanko Parking (Staging)",
                    id: "20c33f62-29e5-4e38-a107-0c287d0fd823",
                    environment: .staging
                ),
                Operator(
                    name: "zDanko Parking (Dev)",
                    id: "5e0a5b4b-05dd-4007-811d-b2ddfba268f4",
                    environment: .development
                )
            ]
            
            do {
                for op in defaultOperators {
                    modelContext.insert(op)
                    print("✅ [MIGRATION] Added \(op.name) (\(op.environment?.rawValue ?? "unknown"))")
                }
                try modelContext.save()
                print("✅ [MIGRATION] Successfully migrated \(defaultOperators.count) default operators to SwiftData")
            } catch {
                print("❌ [MIGRATION] Error migrating default operators: \(error)")
            }
        } else {
            print("ℹ️ [MIGRATION] Skipping migration - \(existingOperators.count) operator(s) already exist")
        }
    }
}
