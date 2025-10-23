//
//  OperatorSelectionView.swift
//  PRMonitor
//
//  Created by Michael Danko on 10/5/25.
//

import SwiftUI

struct OperatorSelectionView: View {
    var body: some View {
        NavigationStack {
            List(mockOperators, id: \.id) { op in
                NavigationLink(destination: OperatorView(selectedOperator: op)) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(op.name)
                                .font(.headline)
                            Spacer()
                            Text(op.environment.rawValue.capitalized)
                        }
                        Text(op.id.uuidString)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Operators")
        }
    }
}

#Preview {
    OperatorSelectionView()
}

