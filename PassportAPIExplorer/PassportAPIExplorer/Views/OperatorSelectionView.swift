//
//  OperatorSelectionView.swift
//  Passport API Explorer
//
//  Created by Michael Danko on 10/5/25.
//

import SwiftUI
import SwiftData

struct OperatorSelectionView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("selectedThemeMode") private var selectedThemeMode: ThemeMode = .auto
    @Environment(\.colorScheme) var colorScheme
    @Query private var operators: [Operator]
    @State private var showingAddOperator = false
    @State private var operatorToEdit: Operator?
    @State private var dataService: OperatorDataService?
    @State private var isRefreshing = false
    
    var body: some View {
        NavigationStack {
            VStack {
                if operators.isEmpty {
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
                    List {
                        ForEach(operators) { op in
                            OperatorCardView(operator: op, colorScheme: colorScheme)
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
                                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .refreshable {
                        await refreshOperators()
                    }
                }
            }
            .navigationTitle(isRefreshing ? "Refreshing..." : "Operators")
            .adaptiveGlassmorphismNavigation()
            .adaptiveGlassmorphismBackground()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddOperator = true
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
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
                print("👁️ [OPERATOR VIEW] Operator selection view appeared")
                print("📅 [OPERATOR VIEW] Time: \(Date())")
                print("🔍 [OPERATOR VIEW] Loaded operators count: \(operators.count)")
                
                if operators.isEmpty {
                    print("⚠️ [OPERATOR VIEW] No operators found")
                } else {
                    print("📋 [OPERATOR VIEW] Current operators:")
                    for (index, op) in operators.enumerated() {
                        print("   [OPERATOR VIEW] \(index + 1). '\(op.name)' (ID: \(op.id))")
                    }
                }
                
                if dataService == nil {
                    print("🔧 [OPERATOR VIEW] Initializing OperatorDataService...")
                    dataService = OperatorDataService(modelContext: modelContext)
                    print("🔄 [OPERATOR VIEW] Checking for mock data migration...")
                    dataService?.migrateFromMockDataIfNeeded()
                }
            }
        }
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

struct OperatorCardView: View {
    let `operator`: Operator
    let colorScheme: ColorScheme
    
    @State private var isPressed = false
    
    var body: some View {
        NavigationLink(destination: OperatorView(selectedOperator: `operator`)) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(`operator`.name)
                        .font(.headline)
                        .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
                    Spacer()
                    Text(`operator`.environment?.rawValue.capitalized ?? "Unknown")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(environmentColor(for: `operator`.environment ?? .production))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                Text("ID: \(`operator`.id)")
                    .font(.caption)
                    .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .adaptiveGlassmorphismListRow()
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .opacity(isPressed ? 0.8 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
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
    OperatorSelectionView()
        .modelContainer(for: Operator.self, inMemory: true)
}

