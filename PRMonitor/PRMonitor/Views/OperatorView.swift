//
//  OperatorView.swift
//  PRMonitor
//
//  Created by Michael Danko on 10/6/25.
//

import SwiftUI

struct OperatorView: View {
    var selectedOperator: Operator
    var selectedZone: Zone?
    
    @State private var searchText = ""
    
    // Computed property to filter zones based on search text
    private var filteredZones: [Zone] {
        if searchText.isEmpty {
            return selectedOperator.zones
        } else {
            return selectedOperator.zones.filter { zone in
                zone.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        
        VStack(spacing: 0) {
            VStack {
                Text("Choose a zone")
                    .padding(.top)
                    .font(.title2)
                    .multilineTextAlignment(.leading)
            }
            
            // Search bar for filtering zones
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Search zones...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
            
            if filteredZones.isEmpty && !searchText.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    Text("No zones found")
                        .font(.headline)
                        .foregroundColor(.gray)
                    Text("Try adjusting your search terms")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(filteredZones) { zone in
                        NavigationLink(destination: ParkingRightListView(zone: zone)) {
                            Text(zone.name)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
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
    OperatorView(selectedOperator: charlotte)
}
