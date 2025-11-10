//
//  OperatorsListCard.swift
//  Passport API Explorer
//
//  Created by Michael Danko on 10/30/25.
//

import SwiftUI
import SwiftData

/// Card component displaying a list of operators with edit/delete actions.
struct OperatorsListCard: View {
    let operators: [Operator]
    let onEdit: (Operator) -> Void
    let onDelete: (Operator) -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
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
                    .listRowSeparator(.hidden)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive, action: { onDelete(op) }) {
                            Label("Delete", systemImage: "trash")
                        }
                        
                        Button(action: { onEdit(op) }) {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(.blue)
                    }
                    .contextMenu {
                        Button(action: { onEdit(op) }) {
                            Label("Edit", systemImage: "pencil")
                        }
                        
                        Button(role: .destructive, action: { onDelete(op) }) {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .frame(height: CGFloat(operators.count) * 70)
            .scrollDisabled(true)
            .scrollContentBackground(.hidden)
            .listStyle(.plain)
            .listSectionSeparator(.hidden)
        }
        .padding()
        .adaptiveGlassmorphismCard()
    }
}

#Preview {
    let container = try! ModelContainer(
        for: Operator.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    
    let context = container.mainContext
    let op1 = Operator(name: "Test Operator 1", id: UUID().uuidString, environment: .development)
    let op2 = Operator(name: "Test Operator 2", id: UUID().uuidString, environment: .production)
    context.insert(op1)
    context.insert(op2)
    
    return OperatorsListCard(
        operators: [op1, op2],
        onEdit: { _ in },
        onDelete: { _ in }
    )
    .padding()
    .adaptiveGlassmorphismBackground()
    .modelContainer(container)
}

