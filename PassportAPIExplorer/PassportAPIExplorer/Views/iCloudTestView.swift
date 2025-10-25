//
//  iCloudTestView.swift
//  Passport API Explorer
//
//  Created by Michael Danko on 10/22/25.
//

import SwiftUI
import SwiftData

struct iCloudTestView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var operators: [Operator]
    @State private var dataService: OperatorDataService?
    @State private var testOperatorName = "iCloud Test Operator"
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("iCloud Sync Test")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("This view helps test iCloud synchronization. Add a test operator and check if it appears on other devices.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                
                VStack(spacing: 16) {
                    TextField("Test Operator Name", text: $testOperatorName)
                        .textFieldStyle(.roundedBorder)
                    
                    Button("Add Test Operator") {
                        addTestOperator()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(testOperatorName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    
                    if !operators.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Current Operators (\(operators.count))")
                                .font(.headline)
                            
                            ForEach(operators) { op in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(op.name)
                                            .font(.subheadline)
                                        Text("ID: \(op.id)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Text(op.environment?.rawValue.capitalized ?? "Unknown")
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(4)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
                .padding()
                
                Spacer()
                
                VStack(spacing: 8) {
                    Text("iCloud Status")
                        .font(.headline)
                    
                    HStack {
                        Image(systemName: "externaldrive")
                            .foregroundColor(.blue)
                        Text("SwiftData enabled (local storage)")
                            .font(.subheadline)
                    }
                    
                    Text("iCloud sync can be enabled later in project settings")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding()
            }
            .navigationTitle("iCloud Test")
            .onAppear {
                if dataService == nil {
                    dataService = OperatorDataService(modelContext: modelContext)
                }
            }
        }
    }
    
    private func addTestOperator() {
        let trimmedName = testOperatorName.trimmingCharacters(in: .whitespacesAndNewlines)
        if let newOperator = dataService?.addOperator(name: trimmedName, id: UUID().uuidString, environment: .development) {
            print("✅ Test operator added: \(newOperator.name)")
            testOperatorName = "iCloud Test Operator" // Reset for next test
        }
    }
}

#Preview {
    iCloudTestView()
        .modelContainer(for: Operator.self, inMemory: true)
}
