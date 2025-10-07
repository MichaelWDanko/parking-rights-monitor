//
//  ZoneSelectionView.swift
//  PRMonitor
//
//  Created by Michael Danko on 10/6/25.
//

import SwiftUI

struct ZoneSelectionView: View {
    var selectedOperator: Operator
    var selectedZone: Zone?
    
    var body: some View {
        
        VStack(spacing: 0) {
            VStack {
                Text("Choose a zone")
                    .padding(.top)
//                    .frame(maxWidth: .infinity)
                    .font(.title2)
                    .multilineTextAlignment(.leading)
//                    .background(Color(.systemBackground))
            }
            List {
                ForEach(selectedOperator.zones) { zone in
                    NavigationLink(destination: PRListView(zone: zone)) {
                        Text(zone.name)
                    }
                }
            }
            /* .listStyle(.plain) */
            .scrollContentBackground(.hidden)

        }
        .navigationTitle(selectedOperator.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {}) {
                    Image(systemName: "arrow.clockwise.circle")
                }
            }
        }
    }
}

#Preview {
    ZoneSelectionView(selectedOperator: charlotte)
}
