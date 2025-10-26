//
//  EditOperatorView.swift
//  Passport API Explorer
//
//  Created by Michael Danko on 10/22/25.
//

import SwiftUI
import SwiftData

struct EditOperatorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @AppStorage("selectedThemeMode") private var selectedThemeMode: ThemeMode = .auto
    @Environment(\.colorScheme) var colorScheme
    
    let operatorToEdit: Operator
    
    @State private var operatorName: String
    @State private var operatorIdString: String
    @State private var selectedEnvironment: OperatorEnvironment
    @State private var dataService: OperatorDataService?
    @State private var showingError = false
    @State private var errorMessage = ""
    
    init(operatorToEdit: Operator) {
        self.operatorToEdit = operatorToEdit
        self._operatorName = State(initialValue: operatorToEdit.name)
        self._operatorIdString = State(initialValue: operatorToEdit.id)
        self._selectedEnvironment = State(initialValue: operatorToEdit.environment ?? .production)
    }
    
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
                
                Section(footer: Text("The operator ID is the UUID that will be passed to your API. Changes will be saved locally and synced to iCloud if enabled.").foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))) {
                    EmptyView()
                }
                .listRowBackground(Color.glassBackground)
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("Edit Operator")
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
                        saveChanges()
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
    
    private func saveChanges() {
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
        
        // Validate UUID format
        let isValidUUID = UUID(uuidString: trimmedIdString) != nil
        if !isValidUUID {
            errorMessage = "Operator ID must be a valid UUID format"
            showingError = true
            return
        }
        
        // Check for duplicate names (excluding current operator)
        let existingOperators = dataService?.fetchOperators() ?? []
        if existingOperators.contains(where: { $0.id != operatorToEdit.id && $0.name.lowercased() == trimmedName.lowercased() }) {
            errorMessage = "An operator with this name already exists"
            showingError = true
            return
        }
        
        // Check for duplicate operator IDs (excluding current operator)
        if existingOperators.contains(where: { $0.id != operatorToEdit.id && $0.id == trimmedIdString }) {
            errorMessage = "An operator with this ID already exists"
            showingError = true
            return
        }
        
        dataService?.updateOperator(operatorToEdit, name: trimmedName, id: trimmedIdString, environment: selectedEnvironment)
        dismiss()
    }
}

#Preview {
    let sampleOperator = Operator(name: "Sample Operator", id: UUID().uuidString, environment: .production)
    return EditOperatorView(operatorToEdit: sampleOperator)
        .modelContainer(for: Operator.self, inMemory: true)
}
