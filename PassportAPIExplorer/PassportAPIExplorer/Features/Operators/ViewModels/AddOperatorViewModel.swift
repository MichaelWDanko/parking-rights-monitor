//
//  AddOperatorViewModel.swift
//  Passport API Explorer
//
//  Created by Michael Danko on 10/30/25.
//

import Foundation
import SwiftData
import Observation

extension AddOperatorView {
    @Observable
    @MainActor
    class AddOperatorViewModel {
        // MARK: - Form State
        
        var operatorName = ""
        var operatorIdString = ""
        var selectedEnvironment: OperatorEnvironment = .production
        
        // MARK: - Error State
        
        var showingError = false
        var errorMessage = ""
        
        // MARK: - Dependencies
        
        private let dataService: OperatorDataService
        
        // MARK: - Initialization
        
        init(dataService: OperatorDataService) {
            self.dataService = dataService
        }
        
        // MARK: - Computed Properties
        
        var isFormValid: Bool {
            let trimmedName = operatorName.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedIdString = operatorIdString.trimmingCharacters(in: .whitespacesAndNewlines)
            return !trimmedName.isEmpty && !trimmedIdString.isEmpty
        }
        
        // MARK: - Actions
        
        func saveOperator() -> Operator? {
            let trimmedName = operatorName.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedIdString = operatorIdString.trimmingCharacters(in: .whitespacesAndNewlines)
            
            guard !trimmedName.isEmpty else {
                errorMessage = "Operator name cannot be empty"
                showingError = true
                return nil
            }
            
            guard !trimmedIdString.isEmpty else {
                errorMessage = "Operator ID cannot be empty"
                showingError = true
                return nil
            }
            
            guard trimmedName.count >= 2 else {
                errorMessage = "Operator name must be at least 2 characters long"
                showingError = true
                return nil
            }
            
            // Validate UUID format (optional - we can accept any string now)
            let isValidUUID = UUID(uuidString: trimmedIdString) != nil
            if !isValidUUID {
                errorMessage = "Operator ID must be a valid UUID format"
                showingError = true
                return nil
            }
            
            // Check for duplicate names
            let existingOperators = dataService.fetchOperators()
            if existingOperators.contains(where: { $0.name.lowercased() == trimmedName.lowercased() }) {
                errorMessage = "An operator with this name already exists"
                showingError = true
                return nil
            }
            
            // Check for duplicate operator IDs
            if existingOperators.contains(where: { $0.id == trimmedIdString }) {
                errorMessage = "An operator with this ID already exists"
                showingError = true
                return nil
            }
            
            if let newOperator = dataService.addOperator(name: trimmedName, id: trimmedIdString, environment: selectedEnvironment) {
                print("Successfully added operator: \(newOperator.name) with ID: \(newOperator.id)")
                return newOperator
            } else {
                errorMessage = "Failed to save operator. Please try again."
                showingError = true
                return nil
            }
        }
    }
}

