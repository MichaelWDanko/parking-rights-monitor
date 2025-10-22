//
//  PRListView.swift
//  PRMonitor
//
//  Created by Michael Danko on 10/6/25.
//

import SwiftUI

struct PRListView: View {
    
    let zone: Zone

    let mockRight = ParkingRight(
        id: "0800fc577294c34e0b28ad2839435945",
        operator_id: "6c90fda7-e2cf-4d54-ae7c-9a3e47e09c01",
        zone_id: "64b64b7e-6f9c-446c-a0b7-72723a6321a0",
        start_time: "2025-04-01 10:00:00Z",
        end_time: "2025-04-01 16:27:00Z",
        vehicle_plate: "ABC123",
        vehicle_state: "SC",
        space_number: "5"
    )
    
    var body: some View {
        ScrollView {
            LazyVStack {
                Text(zone.name)
                ParkingRightView(pr: mockRight)
                ParkingRightView(pr: mockRight)
                ParkingRightView(pr: mockRight)
            }
        }
    }
}

#Preview {
    PRListView(
        zone: charlotte.zones.first ?? Zone(id: UUID(), name: "Sample Zone", number: "S-001", operator_id: charlotte.id)
    )
}
