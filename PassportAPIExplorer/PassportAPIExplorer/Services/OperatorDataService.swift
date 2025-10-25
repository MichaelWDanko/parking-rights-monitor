//
//  OperatorDataService.swift
//  Passport API Explorer
//
//  Created by Michael Danko on 10/22/25.
//

import Foundation
import SwiftData

@Observable
class OperatorDataService {
    private var modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - CRUD Operations
    
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
    
    func updateOperator(_ operator: Operator, name: String, id: String, environment: OperatorEnvironment) {
        `operator`.name = name
        `operator`.id = id
        `operator`.environment = environment
        
        do {
            try modelContext.save()
            print("✅ Successfully updated operator: \(`operator`.name) (ID: \(`operator`.id))")
            print("☁️ Changes will sync to iCloud automatically")
        } catch {
            print("❌ Error updating operator: \(error)")
        }
    }
    
    func deleteOperator(_ operator: Operator) {
        do {
            let operatorName = `operator`.name
            let operatorId = `operator`.id
            modelContext.delete(`operator`)
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
            // Add the default operator from mock data
            let defaultOperator = Operator(
                name: "zDanko Parking",
                id: "43c401c0-a17e-40e5-ae26-4f5f205bf063",
                environment: .production
            )
            
            do {
                modelContext.insert(defaultOperator)
                try modelContext.save()
                print("Migrated default operator to SwiftData")
            } catch {
                print("Error migrating default operator: \(error)")
            }
        }
    }
}
