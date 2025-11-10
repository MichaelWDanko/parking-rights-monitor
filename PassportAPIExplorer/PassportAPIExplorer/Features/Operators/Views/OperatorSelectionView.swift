//
//  OperatorSelectionView.swift
//  Passport API Explorer
//
//  Created by Michael Danko on 10/5/25.
//

import SwiftUI
import SwiftData

/// Operator selection view for NavigationSplitView sidebar (iPad/Mac)
struct OperatorSelectionView: View {
    @EnvironmentObject var drawerViewModel: OperatorDrawerViewModel
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        OperatorListContent(
            onSelectOperator: { op in
                drawerViewModel.selectOperator(op)
            },
            isIPhone: UIDevice.current.userInterfaceIdiom == .phone,
            selectedOperatorId: .constant(drawerViewModel.selectedOperator?.id)
        )
        .navigationTitle("Operators")
        .adaptiveGlassmorphismNavigation()
        .adaptiveGlassmorphismBackground()
    }
}

#Preview {
    NavigationStack {
        OperatorSelectionView()
            .environmentObject(OperatorDrawerViewModel())
    }
    .modelContainer(for: Operator.self, inMemory: true)
}

