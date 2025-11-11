//
//  OperatorListContent.swift
//  Passport API Explorer
//
//  Created by Michael Danko on 11/10/25.
//

import SwiftUI
import SwiftData

/// Shared operator list content component used in both drawer and NavigationSplitView
struct OperatorListContent: View {
    @Query private var operators: [Operator]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) var colorScheme
    
    let onSelectOperator: (Operator) -> Void
    let isIPhone: Bool
    @Binding var selectedOperatorId: String?
    
    @State private var showingAddOperator = false
    @State private var operatorToEdit: Operator?
    @State private var dataService: OperatorDataService?
    @State private var isRefreshing = false
    
    var body: some View {
        VStack {
            if operators.isEmpty {
                // Empty state
                VStack(spacing: 20) {
                    Image(systemName: "building.2")
                        .font(.system(size: 50))
                        .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                    
                    VStack(spacing: 8) {
                        Text("No Operators")
                            .font(.headline)
                            .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
                        Text("Add your first operator to get started")
                            .font(.subheadline)
                            .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                            .multilineTextAlignment(.center)
                    }
                    
                    Button("Add Operator") {
                        showingAddOperator = true
                    }
                    .buttonStyle(GlassmorphismButtonStyle(isPrimary: true))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .adaptiveGlassmorphismCard()
                .padding()
            } else {
                // Operator list
                List {
                    ForEach(operators) { op in
                        OperatorListCard(
                            op: op,
                            colorScheme: colorScheme,
                            isSelected: selectedOperatorId == op.id,
                            onSelect: {
                                onSelectOperator(op)
                            }
                        )
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                deleteOperator(op)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            
                            Button {
                                operatorToEdit = op
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                        .contextMenu {
                            Button {
                                operatorToEdit = op
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            
                            Button(role: .destructive) {
                                deleteOperator(op)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    }
                }
                .listStyle(.plain)
                .listSectionSeparator(.hidden)
                .scrollContentBackground(.hidden)
                .refreshable {
                    await refreshOperators()
                }
            }
        }
        .sheet(isPresented: $showingAddOperator) {
            AddOperatorView()
        }
        .sheet(item: $operatorToEdit) { op in
            EditOperatorView(operatorToEdit: op)
        }
        .onAppear {
            print("👁️ [OPERATOR LIST] Operator list content appeared")
            print("📅 [OPERATOR LIST] Time: \(Date())")
            print("🔍 [OPERATOR LIST] Loaded operators count: \(operators.count)")
            
            if dataService == nil {
                print("🔧 [OPERATOR LIST] Initializing OperatorDataService...")
                dataService = OperatorDataService(modelContext: modelContext)
                print("🔄 [OPERATOR LIST] Checking for mock data migration...")
                dataService?.migrateFromMockDataIfNeeded()
            }
        }
    }
    
    @MainActor
    private func refreshOperators() async {
        isRefreshing = true
        print("🔄 Refreshing operators...")
        
        // Add a small delay to show the refresh animation
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Force SwiftData to refresh by accessing the modelContext
        do {
            try modelContext.save()
            print("✅ Operators refreshed successfully")
            print("☁️ CloudKit sync will update any changes from other devices")
        } catch {
            print("❌ Failed to refresh operators: \(error)")
        }
        
        isRefreshing = false
    }
    
    private func deleteOperator(_ op: Operator) {
        modelContext.delete(op)
        do {
            try modelContext.save()
            print("🗑️ Operator deleted: \(op.name)")
        } catch {
            print("❌ Failed to delete operator: \(error.localizedDescription)")
        }
    }
}

/// Individual operator card for the list
struct OperatorListCard: View {
    let op: Operator
    let colorScheme: ColorScheme
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(Color.adaptiveCyanAccent(colorScheme == .dark))
                    }
                    
                    Text(op.name)
                        .font(.headline)
                        .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
                    Spacer()
                    Text(op.environment?.rawValue.capitalized ?? "Unknown")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(environmentColor(for: op.environment ?? .production))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                Text("ID: \(op.id)")
                    .font(.caption)
                    .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .adaptiveGlassmorphismListRow()
        .buttonStyle(PlainButtonStyle())
    }
    
    private func environmentColor(for environment: OperatorEnvironment) -> Color {
        switch environment {
        case .production:
            return .green
        case .staging:
            return .orange
        case .development:
            return .blue
        }
    }
}

#Preview {
    OperatorListContent(
        onSelectOperator: { _ in },
        isIPhone: true,
        selectedOperatorId: .constant(nil)
    )
    .modelContainer(for: Operator.self, inMemory: true)
}

