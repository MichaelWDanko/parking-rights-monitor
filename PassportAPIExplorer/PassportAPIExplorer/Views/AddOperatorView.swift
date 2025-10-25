//
//  AddOperatorView.swift
//  Passport API Explorer
//
//  Created by Michael Danko on 10/22/25.
//

import SwiftUI
import SwiftData

struct AddOperatorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @AppStorage("selectedThemeMode") private var selectedThemeMode: ThemeMode = .auto
    @Environment(\.colorScheme) var colorScheme
    
    @State private var operatorName = ""
    @State private var operatorIdString = ""
    @State private var selectedEnvironment: OperatorEnvironment = .production
    @State private var dataService: OperatorDataService?
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Operator Details").foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))) {
                    TextField("Operator Name", text: $operatorName)
                        .adaptiveGlassmorphismTextField()
                    
                    TextField("Operator ID (UUID)", text: $operatorIdString)
                        .adaptiveGlassmorphismTextField()
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    Picker("Environment", selection: $selectedEnvironment) {
                        ForEach(OperatorEnvironment.allCases, id: \.self) { environment in
                            Text(environment.rawValue.capitalized)
                                .tag(environment)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .listRowBackground(Color.glassBackground)
                
                Section(footer: Text("The operator ID is the UUID that will be passed to your API. The operator will be saved locally and synced to iCloud if enabled.").foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))) {
                    EmptyView()
                }
                .listRowBackground(Color.glassBackground)
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("Add Operator")
            .navigationBarTitleDisplayMode(.inline)
.adaptiveGlassmorphismNavigation()
.adaptiveGlassmorphismBackground()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveOperator()
                    }
                    .disabled(operatorName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || operatorIdString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
                }
            }
            .onAppear {
                if dataService == nil {
                    dataService = OperatorDataService(modelContext: modelContext)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func saveOperator() {
        let trimmedName = operatorName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedIdString = operatorIdString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty else {
            errorMessage = "Operator name cannot be empty"
            showingError = true
            return
        }
        
        guard !trimmedIdString.isEmpty else {
            errorMessage = "Operator ID cannot be empty"
            showingError = true
            return
        }
        
        guard trimmedName.count >= 2 else {
            errorMessage = "Operator name must be at least 2 characters long"
            showingError = true
            return
        }
        
        // Validate UUID format (optional - we can accept any string now)
        let isValidUUID = UUID(uuidString: trimmedIdString) != nil
        if !isValidUUID {
            errorMessage = "Operator ID must be a valid UUID format"
            showingError = true
            return
        }
        
        // Check for duplicate names
        let existingOperators = dataService?.fetchOperators() ?? []
        if existingOperators.contains(where: { $0.name.lowercased() == trimmedName.lowercased() }) {
            errorMessage = "An operator with this name already exists"
            showingError = true
            return
        }
        
        // Check for duplicate operator IDs
        if existingOperators.contains(where: { $0.id == trimmedIdString }) {
            errorMessage = "An operator with this ID already exists"
            showingError = true
            return
        }
        
        if let newOperator = dataService?.addOperator(name: trimmedName, id: trimmedIdString, environment: selectedEnvironment) {
            print("Successfully added operator: \(newOperator.name) with ID: \(newOperator.id)")
            dismiss()
        } else {
            errorMessage = "Failed to save operator. Please try again."
            showingError = true
        }
    }
}

#Preview {
    AddOperatorView()
        .modelContainer(for: Operator.self, inMemory: true)
}
