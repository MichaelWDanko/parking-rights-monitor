//
//  EditOperatorSheet.swift
//  Passport API Explorer
//
//  Created by Michael Danko on 10/30/25.
//

import SwiftUI

/// Sheet component for editing an operator's name.
struct EditOperatorSheet: View {
    let operatorToEdit: Operator
    @Binding var editedName: String
    let onSave: () -> Void
    let onCancel: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
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
                
                Button("Save Changes", action: onSave)
                    .buttonStyle(GlassmorphismButtonStyle(isPrimary: true))
                    .disabled(editedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .padding(.horizontal)
                
                Spacer()
            }
            .adaptiveGlassmorphismBackground()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                        .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
                }
            }
        }
        .presentationDetents([.height(300)])
    }
}

#Preview {
    let mockOperator = Operator(name: "Test Operator", id: UUID().uuidString, environment: .development)
    
    EditOperatorSheet(
        operatorToEdit: mockOperator,
        editedName: .constant("Test Operator"),
        onSave: {},
        onCancel: {}
    )
}

