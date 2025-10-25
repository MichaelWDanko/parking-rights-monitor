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
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(operators) { op in
                                NavigationLink(destination: OperatorView(selectedOperator: op)) {
                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack {
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
                                }
                                .adaptiveGlassmorphismCard()
                                .buttonStyle(PlainButtonStyle())
                                .contextMenu {
                                    Button(role: .destructive) {
                                        dataService?.deleteOperator(op)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    
                                    Button {
                                        operatorToEdit = op
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 20)
                    }
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
                if dataService == nil {
                    dataService = OperatorDataService(modelContext: modelContext)
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
}

#Preview {
    OperatorSelectionView()
        .modelContainer(for: Operator.self, inMemory: true)
}

