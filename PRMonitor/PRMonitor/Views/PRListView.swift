//
//  PRListView.swift
//  PRMonitor
//
//  Created by Michael Danko on 10/6/25.
//

import SwiftUI

struct PRListView: View {
    
    let zone: Zone
    
    var body: some View {
        VStack {
            Text(zone.name)
            ParkingRightView()
            ParkingRightView()
            ParkingRightView()
        }
    }
}

#Preview {
    PRListView(zone: charlotte.zones.first!)
}
