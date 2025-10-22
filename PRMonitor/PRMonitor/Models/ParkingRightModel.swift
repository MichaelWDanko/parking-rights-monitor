//
//  ParkingRightModel.swift
//  PRMonitor
//
//  Created by Michael Danko on 10/6/25.
//

import Foundation

struct ParkingRight: Identifiable, Codable {
    let id: String
    let operator_id: String
    let zone_id: String
    
    let start_time: String
    let end_time: String

    let vehicle_plate: String?
    let vehicle_state: String?
    let space_number: String?
    
    init(id: String, operator_id: String, zone_id: String, start_time: String, end_time: String, vehicle_plate: String?, vehicle_state: String?, space_number: String?) {
        self.id = id
        self.operator_id = operator_id
        self.zone_id = zone_id
        
        self.start_time = start_time
        self.end_time = end_time

        self.vehicle_plate = vehicle_plate
        self.vehicle_state = vehicle_state
        self.space_number = space_number
    }
    
}
