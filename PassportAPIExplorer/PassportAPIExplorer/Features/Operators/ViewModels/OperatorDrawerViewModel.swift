//
//  OperatorDrawerViewModel.swift
//  Passport API Explorer
//
//  Created by Michael Danko on 11/10/25.
//

import SwiftUI
import Combine

/// View model for managing operator drawer state and selected operator
@MainActor
class OperatorDrawerViewModel: ObservableObject {
    /// Controls whether the drawer is currently open
    @Published var isDrawerOpen: Bool = false
    
    /// The currently selected operator for the session (not persisted)
    @Published var selectedOperator: Operator?
    
    /// Opens the drawer with animation
    func openDrawer() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            isDrawerOpen = true
        }
    }
    
    /// Closes the drawer with animation
    func closeDrawer() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            isDrawerOpen = false
        }
    }
    
    /// Selects an operator and closes the drawer
    /// - Parameter op: The operator to select
    func selectOperator(_ op: Operator) {
        selectedOperator = op
        closeDrawer()
    }
}

