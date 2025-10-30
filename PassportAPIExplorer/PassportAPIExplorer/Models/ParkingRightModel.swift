//
//  ParkingRightModel.swift
//  Passport API Explorer
//
//  Created by Michael Danko on 10/6/25.
//

import Foundation

struct Vehicle: Codable {
    let vehiclePlate: String?
    let vehicleState: String?
    
    // Legacy computed properties for backward compatibility
    var vehicle_plate: String? { return vehiclePlate }
    var vehicle_state: String? { return vehicleState }
    
    enum CodingKeys: String, CodingKey {
        case vehiclePlate, vehicleState
    }
    
    // Custom initializer to handle API response safely
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        vehiclePlate = try container.decodeIfPresent(String.self, forKey: .vehiclePlate)
        vehicleState = try container.decodeIfPresent(String.self, forKey: .vehicleState)
    
    }
    
    // Manual initializer
    init(vehiclePlate: String?, vehicleState: String?) {
        self.vehiclePlate = vehiclePlate
        self.vehicleState = vehicleState
    }
}

struct ParkingRight: Identifiable, Codable {
    let id: String
    let operatorId: String
    let zoneId: String
    let type: String
    let startTime: String
    let endTime: String
    let vehicle: Vehicle?
    let referenceId: String?
    let spaceNumber: String?
    
    // Computed properties for backward compatibility
    var vehicle_plate: String? {
        return vehicle?.vehicle_plate 
    }
    var vehicle_state: String? { 
        return vehicle?.vehicle_state 
    }
    
    // Legacy computed properties for backward compatibility
    var operator_id: String { return operatorId }
    var zone_id: String { return zoneId }
    var start_time: String { return startTime }
    var end_time: String { return endTime }
    var reference_id: String? { return referenceId }
    var space_number: String? { return spaceNumber }
    
    enum CodingKeys: String, CodingKey {
        case id, operatorId, zoneId, type, startTime, endTime, vehicle, referenceId, spaceNumber
    }
    
    // Custom initializer for creating ParkingRight instances manually
    init(id: String, operatorId: String, zoneId: String, type: String, startTime: String, endTime: String, vehicle: Vehicle?, referenceId: String?, spaceNumber: String?) {
        self.id = id
        self.operatorId = operatorId
        self.zoneId = zoneId
        self.type = type
        self.startTime = startTime
        self.endTime = endTime
        self.vehicle = vehicle
        self.referenceId = referenceId
        self.spaceNumber = spaceNumber
    }
    
    var timeRemainingInSeconds: TimeInterval {
        let isoDateFormatter = ISO8601DateFormatter()
        isoDateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let formattedEndDate = isoDateFormatter.date(from: endTime) else {
            // Try without fractional seconds
            isoDateFormatter.formatOptions = [.withInternetDateTime]
            guard let formattedEndDate = isoDateFormatter.date(from: endTime) else {
                return 0
            }
            return formattedEndDate.timeIntervalSince(Date())
        }
        
        return formattedEndDate.timeIntervalSince(Date())
    }
    
    var timeRemainingDescription: String {
        if timeRemainingInSeconds <= 0 {
            return "Expired"
        }
        
        let totalSeconds = Int(timeRemainingInSeconds)
        let days = totalSeconds / 86400
        let hours = (totalSeconds % 86400) / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if days > 0 {
            return "\(days) day\(days == 1 ? "" : "s"), \(hours) hour\(hours == 1 ? "" : "s")"
        }
        
        if hours > 0 {
            return "\(hours) hour\(hours == 1 ? "" : "s"), \(minutes) minute\(minutes == 1 ? "" : "s")"
        }
        
        if minutes > 0 {
            return "\(minutes) minute\(minutes == 1 ? "" : "s"), \(seconds) second\(seconds == 1 ? "" : "s")"
        }
        
        return "\(seconds) second\(seconds == 1 ? "" : "s")"
    }
}
