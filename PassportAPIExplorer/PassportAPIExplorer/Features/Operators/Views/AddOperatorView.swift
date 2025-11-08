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
    
    @State private var viewModel: AddOperatorViewModel?
    
    var body: some View {
        NavigationStack {
            if let viewModel = viewModel {
                @Bindable var vm = viewModel
                Form {
                    Section(header: Text("Operator Details").foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))) {
                        TextField("Operator Name", text: $vm.operatorName)
                            .adaptiveGlassmorphismTextField()
                        
                        TextField("Operator ID (UUID)", text: $vm.operatorIdString)
                            .adaptiveGlassmorphismTextField()
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        
                        Picker("Environment", selection: $vm.selectedEnvironment) {
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
                            if vm.saveOperator() {
                                dismiss()
                            }
                        }
                        .disabled(!vm.isFormValid)
                        .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
                    }
                }
                .alert("Error", isPresented: $vm.showingError) {
                    Button("OK") { }
                } message: {
                    Text(vm.errorMessage)
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                let dataService = OperatorDataService(modelContext: modelContext)
                viewModel = AddOperatorViewModel(dataService: dataService)
            }
        }
    }
}

#Preview {
    AddOperatorView()
        .modelContainer(for: Operator.self, inMemory: true)
}
