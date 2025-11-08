//
//  EditOperatorViewModel.swift
//  Passport API Explorer
//
//  Created by Michael Danko on 10/30/25.
//

import Foundation
import SwiftData
import Observation

extension EditOperatorView {
    @Observable
    @MainActor
    class EditOperatorViewModel {
        // MARK: - Form State
        
        var operatorName: String
        var operatorIdString: String
        var selectedEnvironment: OperatorEnvironment
        
        // MARK: - Error State
        
        var showingError = false
        var errorMessage = ""
        
        // MARK: - Dependencies
        
        private let operatorToEdit: Operator
        private let dataService: OperatorDataService
        
        // MARK: - Initialization
        
        init(operatorToEdit: Operator, dataService: OperatorDataService) {
            self.operatorToEdit = operatorToEdit
            self.operatorName = operatorToEdit.name
            self.operatorIdString = operatorToEdit.id
            self.selectedEnvironment = operatorToEdit.environment ?? .production
            self.dataService = dataService
        }
        
        // MARK: - Computed Properties
        
        var isFormValid: Bool {
            let trimmedName = operatorName.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedIdString = operatorIdString.trimmingCharacters(in: .whitespacesAndNewlines)
            return !trimmedName.isEmpty && !trimmedIdString.isEmpty
        }
        
        // MARK: - Actions
        
        func saveChanges() -> Bool {
            let trimmedName = operatorName.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedIdString = operatorIdString.trimmingCharacters(in: .whitespacesAndNewlines)
            
            guard !trimmedName.isEmpty else {
                errorMessage = "Operator name cannot be empty"
                showingError = true
                return false
            }
            
            guard !trimmedIdString.isEmpty else {
                errorMessage = "Operator ID cannot be empty"
                showingError = true
                return false
            }
            
            guard trimmedName.count >= 2 else {
                errorMessage = "Operator name must be at least 2 characters long"
                showingError = true
                return false
            }
            
            // Validate UUID format
            let isValidUUID = UUID(uuidString: trimmedIdString) != nil
            if !isValidUUID {
                errorMessage = "Operator ID must be a valid UUID format"
                showingError = true
                return false
            }
            
            // Check for duplicate names (excluding current operator)
            let existingOperators = dataService.fetchOperators()
            if existingOperators.contains(where: { $0.id != operatorToEdit.id && $0.name.lowercased() == trimmedName.lowercased() }) {
                errorMessage = "An operator with this name already exists"
                showingError = true
                return false
            }
            
            // Check for duplicate operator IDs (excluding current operator)
            if existingOperators.contains(where: { $0.id != operatorToEdit.id && $0.id == trimmedIdString }) {
                errorMessage = "An operator with this ID already exists"
                showingError = true
                return false
            }
            
            dataService.updateOperator(operatorToEdit, name: trimmedName, id: trimmedIdString, environment: selectedEnvironment)
            return true
        }
    }
}

