//
//  DrawerOperatorListView.swift
//  Passport API Explorer
//
//  Created by Michael Danko on 11/10/25.
//

import SwiftUI
import SwiftData

/// Operator list component for the drawer
struct DrawerOperatorListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) var colorScheme
    @Query private var operators: [Operator]
    @EnvironmentObject var drawerViewModel: OperatorDrawerViewModel
    @State private var showingAddOperator = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Operators")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
                
                Spacer()
                
                Button(action: {
                    showingAddOperator = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(Color.adaptiveCyanAccent(colorScheme == .dark))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)
            
            Divider()
                .background(Color.adaptiveTextSecondary(colorScheme == .dark).opacity(0.3))
                .padding(.horizontal, 20)
            
            // Operator List
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
                .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(operators) { op in
                            DrawerOperatorCardView(
                                operator: op,
                                isSelected: drawerViewModel.selectedOperator?.id == op.id,
                                colorScheme: colorScheme
                            )
                            .onTapGesture {
                                drawerViewModel.selectOperator(op)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
        }
        .sheet(isPresented: $showingAddOperator) {
            AddOperatorView()
        }
    }
}

/// Individual operator card for the drawer
struct DrawerOperatorCardView: View {
    let `operator`: Operator
    let isSelected: Bool
    let colorScheme: ColorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(Color.adaptiveCyanAccent(colorScheme == .dark))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(`operator`.name)
                        .font(.headline)
                        .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
                    
                    Text("ID: \(`operator`.id)")
                        .font(.caption)
                        .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Environment badge
                Text(`operator`.environment?.rawValue.capitalized ?? "Unknown")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(environmentColor(for: `operator`.environment ?? .production))
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isSelected ? 
                      Color.adaptiveCyanAccent(colorScheme == .dark).opacity(0.15) :
                      Color.adaptiveGlassBackground(colorScheme == .dark)
                )
                .overlay(
                    Group {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.adaptiveCyanAccent(colorScheme == .dark).opacity(0.5), lineWidth: 2)
                        } else {
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(colorScheme == .dark ? 0.2 : 0.1),
                                            Color.white.opacity(colorScheme == .dark ? 0.05 : 0.02)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        }
                    }
                )
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
        .contentShape(Rectangle())
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
    DrawerOperatorListView()
        .environmentObject(OperatorDrawerViewModel())
        .modelContainer(for: Operator.self, inMemory: true)
}

