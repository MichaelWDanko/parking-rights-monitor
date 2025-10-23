//
//  ParkingRightListView.swift
//  PRMonitor
//
//  Created by Michael Danko on 10/6/25.
//

import SwiftUI

struct ParkingRightListView: View {
    
    let zone: Zone
    
    @State private var searchText = ""

    // Mock parking rights for this zone
    let mockRights = [
        ParkingRight(
            id: "0800fc577294c34e0b28ad2839435945",
            operator_id: "6c90fda7-e2cf-4d54-ae7c-9a3e47e09c01",
            zone_id: "64b64b7e-6f9c-446c-a0b7-72723a6321a0",
            start_time: "2025-04-01 10:00:00Z",
            end_time: "2025-04-01 16:27:00Z",
            vehicle_plate: "ABC123",
            vehicle_state: "SC",
            space_number: "5"
        ),
        ParkingRight(
            id: "0800fc577294c34e0b28ad2839435946",
            operator_id: "6c90fda7-e2cf-4d54-ae7c-9a3e47e09c01",
            zone_id: "64b64b7e-6f9c-446c-a0b7-72723a6321a0",
            start_time: "2025-04-01 11:30:00Z",
            end_time: "2025-04-01 18:00:00Z",
            vehicle_plate: "XYZ789",
            vehicle_state: "NC",
            space_number: "12"
        ),
        ParkingRight(
            id: "0800fc577294c34e0b28ad2839435947",
            operator_id: "6c90fda7-e2cf-4d54-ae7c-9a3e47e09c01",
            zone_id: "64b64b7e-6f9c-446c-a0b7-72723a6321a0",
            start_time: "2025-04-01 09:15:00Z",
            end_time: "2025-04-01 15:45:00Z",
            vehicle_plate: "DEF456",
            vehicle_state: "SC",
            space_number: "8"
        )
    ]
    
    // Computed property to filter parking rights based on search text
    private var filteredRights: [ParkingRight] {
        if searchText.isEmpty {
            return mockRights
        } else {
            return mockRights.filter { parkingRight in
                parkingRight.vehicle_plate?.localizedCaseInsensitiveContains(searchText) == true ||
                parkingRight.space_number?.localizedCaseInsensitiveContains(searchText) == true ||
                parkingRight.vehicle_state?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search bar for filtering parking rights
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Filter parking rights...", text: $searchText)
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
            .padding(.bottom, 2)
            .background(Color(.systemBackground))
            
            if filteredRights.isEmpty && !searchText.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    Text("No parking rights found")
                        .font(.headline)
                        .foregroundColor(.gray)
                    Text("Try adjusting your search terms")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
            } else {
                List(filteredRights) { parkingRight in
                    ParkingRightView(pr: parkingRight)
                }
                .scrollContentBackground(.hidden)
                .background(Color(.systemBackground))
            }
        }
        .background(Color(.systemBackground))
        .navigationTitle(zone.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    // Create a sample zone for preview
    let sampleZone = Zone(
        id: "sample-zone-id",
        name: "Sample Zone",
        number: "S-001",
        operator_id: zdanko.id.uuidString
    )
    
    ParkingRightListView(zone: sampleZone)
}
