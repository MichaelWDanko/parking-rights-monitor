//
//  ParkingSessionEventModel.swift
//  Passport API Explorer
//
//  Created by Michael Danko on 10/30/25.
//

import Foundation
import SwiftData

// MARK: - Event Type Enum

/// Event types supported by the Passport API parking session events endpoint.
/// These represent the lifecycle of a parking session: start, extend, stop.
enum ParkingSessionEventType: String, Codable, CaseIterable {
    case started = "parking_session_started"
    case extended = "parking_session_extended"
    case stopped = "parking_session_stopped"
    
    var displayName: String {
        switch self {
        case .started: return "Started"
        case .extended: return "Extended"
        case .stopped: return "Stopped"
        }
    }
}

// MARK: - Zone ID Type

/// Zone identifier types: Passport zones (UUIDs) or external zones (third-party IDs).
/// The API accepts either type, but only one should be provided per event.
enum ZoneIDType: String, Codable, CaseIterable {
    case passport = "Passport Zone ID"
    case external = "External Zone ID"
    
    var description: String {
        switch self {
        case .passport: return "UUID from Passport system"
        case .external: return "Third-party zone identifier"
        }
    }
}

// MARK: - Session ID Generator

/// Generates a unique session ID in the format: apie-YYYY-MM-DD-#####
/// Session IDs must be unique per parking session and are used to track
/// the session lifecycle (start → extend → stop) across multiple API calls.
extension ParkingSession {
    static func generateSessionId() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: Date())
        
        // Generate random 5 digits
        let randomDigits = String(format: "%05d", Int.random(in: 0...99999))
        
        return "apie-\(dateString)-\(randomDigits)"
    }
}

// MARK: - Parking Session (Local Storage)

/// Local SwiftData model representing a parking session.
/// Stored in CloudKit for cross-device sync. This is the app's local representation;
/// the API uses events (started/extended/stopped) to track sessions server-side.
@Model
class ParkingSession: Identifiable {
    var id: String = UUID().uuidString
    var sessionId: String = ParkingSession.generateSessionId()  // The actual session ID for the API
    var operatorId: String = ""
    var zoneIdType: String = ZoneIDType.passport.rawValue  // Store as string for SwiftData
    var zoneId: String = ""
    var zoneName: String?  // Optional zone name for display
    var vehiclePlate: String = ""
    var vehicleState: String = ""
    var vehicleCountry: String = "US"
    var spaceNumber: String?
    var startTime: Date = Date()
    var endTime: Date = Date()
    var isActive: Bool = true
    var dateCreated: Date = Date()
    
    init(
        sessionId: String? = nil,
        operatorId: String,
        zoneIdType: ZoneIDType = .passport,
        zoneId: String,
        zoneName: String? = nil,
        vehiclePlate: String,
        vehicleState: String,
        vehicleCountry: String = "US",
        spaceNumber: String? = nil,
        startTime: Date = Date(),
        endTime: Date
    ) {
        self.id = UUID().uuidString
        self.sessionId = sessionId ?? ParkingSession.generateSessionId()
        self.operatorId = operatorId
        self.zoneIdType = zoneIdType.rawValue
        self.zoneId = zoneId
        self.zoneName = zoneName
        self.vehiclePlate = vehiclePlate
        self.vehicleState = vehicleState
        self.vehicleCountry = vehicleCountry
        self.spaceNumber = spaceNumber
        self.startTime = startTime
        self.endTime = endTime
        self.isActive = true
        self.dateCreated = Date()
    }
    
    var displayName: String {
        "\(vehiclePlate) (\(vehicleState))"
    }
    
    var computedZoneIdType: ZoneIDType {
        ZoneIDType(rawValue: zoneIdType) ?? .passport
    }
}

// MARK: - API Event Request Models

/// Base protocol for all parking session event data structures.
/// Ensures all events include a sessionId to link them to a specific session.
protocol ParkingSessionEventData: Codable {
    var sessionId: String { get }
}

// MARK: - Shared Models

/// Vehicle information included in parking session events.
/// Maps to API's vehicle_plate, vehicle_state, vehicle_country fields.
struct EventVehicle: Codable {
    let vehiclePlate: String
    let vehicleState: String
    let vehicleCountry: String?
    
    enum CodingKeys: String, CodingKey {
        case vehiclePlate = "vehicle_plate"
        case vehicleState = "vehicle_state"
        case vehicleCountry = "vehicle_country"
    }
}

/// Fee structure for parking session events.
/// Fees are represented as strings (not numbers) to preserve precision and formatting.
/// Used for both event fees (this transaction) and total session fees (cumulative).
struct EventFees: Codable {
    let parkingFee: String
    let convenienceFee: String
    let tax: String
    let currencyCode: String
    
    /// Maps Swift camelCase properties to API's snake_case JSON keys
    enum CodingKeys: String, CodingKey {
        case parkingFee = "parking_fee"
        case convenienceFee = "convenience_fee"
        case tax
        case currencyCode = "currency_code"
    }
}

struct LocationDetails: Codable {
    let latitude: Double
    let longitude: Double
    let accuracy: Double?
    
    enum CodingKeys: String, CodingKey {
        case latitude
        case longitude
        case accuracy
    }
}

struct Payment: Codable {
    let gatewayTransactionId: String?
    let paymentType: String?
    
    enum CodingKeys: String, CodingKey {
        case gatewayTransactionId = "gateway_transaction_id"
        case paymentType = "payment_type"
    }
}

// MARK: - Started Event Data

/// Data structure for parking_session_started events sent to the API.
/// This event creates a new parking session. All fields except optional ones are required.
struct ParkingSessionStartedData: ParkingSessionEventData, Codable {
    let occurredAt: String
    let sessionId: String
    let operatorId: String
    let passportZoneId: String?
    let externalZoneId: String?
    let startTime: String
    let endTime: String
    let accountId: String?
    let vehicle: EventVehicle
    let spaceNumber: String?
    let eventFees: EventFees
    let rateName: String?
    let locationDetails: LocationDetails?
    let payment: Payment?
    
    enum CodingKeys: String, CodingKey {
        case occurredAt = "occurred_at"
        case sessionId = "session_id"
        case operatorId = "operator_id"
        case passportZoneId = "passport_zone_id"
        case externalZoneId = "external_zone_id"
        case startTime = "start_time"
        case endTime = "end_time"
        case accountId = "account_id"
        case vehicle
        case spaceNumber = "space_number"
        case eventFees = "event_fees"
        case rateName = "rate_name"
        case locationDetails = "location_details"
        case payment
    }
}

// MARK: - Extended Event Data

/// Data structure for parking_session_extended events sent to the API.
/// Extends an existing session by updating the end_time and adding new fees.
/// Includes both event fees (this extension) and total session fees (cumulative).
struct ParkingSessionExtendedData: ParkingSessionEventData, Codable {
    let occurredAt: String
    let sessionId: String
    let operatorId: String
    let passportZoneId: String?
    let externalZoneId: String?
    let startTime: String
    let endTime: String
    let accountId: String?
    let vehicle: EventVehicle?
    let spaceNumber: String?
    let eventFees: EventFees
    let totalSessionFees: EventFees
    let rateName: String?
    let locationDetails: LocationDetails?
    let payment: Payment?
    
    enum CodingKeys: String, CodingKey {
        case occurredAt = "occurred_at"
        case sessionId = "session_id"
        case operatorId = "operator_id"
        case passportZoneId = "passport_zone_id"
        case externalZoneId = "external_zone_id"
        case startTime = "start_time"
        case endTime = "end_time"
        case accountId = "account_id"
        case vehicle
        case spaceNumber = "space_number"
        case eventFees = "event_fees"
        case totalSessionFees = "total_session_fees"
        case rateName = "rate_name"
        case locationDetails = "location_details"
        case payment
    }
}

// MARK: - Stopped Event Data

/// Data structure for parking_session_stopped events sent to the API.
/// Marks a session as complete. Can include final fees (may be negative for refunds).
/// Includes both event fees (this stop transaction) and total session fees (final total).
struct ParkingSessionStoppedData: ParkingSessionEventData, Codable {
    let occurredAt: String
    let sessionId: String
    let operatorId: String
    let passportZoneId: String?
    let externalZoneId: String?
    let startTime: String
    let endTime: String
    let accountId: String?
    let vehicle: EventVehicle?
    let spaceNumber: String?
    let eventFees: EventFees
    let totalSessionFees: EventFees
    let rateName: String?
    let locationDetails: LocationDetails?
    let payment: Payment?
    
    enum CodingKeys: String, CodingKey {
        case occurredAt = "occurred_at"
        case sessionId = "session_id"
        case operatorId = "operator_id"
        case passportZoneId = "passport_zone_id"
        case externalZoneId = "external_zone_id"
        case startTime = "start_time"
        case endTime = "end_time"
        case accountId = "account_id"
        case vehicle
        case spaceNumber = "space_number"
        case eventFees = "event_fees"
        case totalSessionFees = "total_session_fees"
        case rateName = "rate_name"
        case locationDetails = "location_details"
        case payment
    }
}

// MARK: - Helper Extensions

/// Converts Date to ISO8601 string format required by the API.
/// Includes fractional seconds for precise timestamp representation.
extension Date {
    func toISO8601String() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: self)
    }
}

