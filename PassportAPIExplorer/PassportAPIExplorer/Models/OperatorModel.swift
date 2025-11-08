//
//  OperatorModel.swift
//  Passport API Explorer
//
//  Created by Michael Danko on 10/5/25.
//

import Foundation
import SwiftData

/// Environment types for parking operators (production, staging, development).
/// Used to organize operators by their API environment.
enum OperatorEnvironment : String, Codable, CaseIterable {
    case production
    case staging
    case development
}

/// Represents a parking zone returned from the API.
/// Zones are areas where parking is managed (e.g., "Downtown Zone 1").
/// This struct maps directly to the API's zone response format.
struct Zone : Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let number: String
    let operator_id: String
    
    /// Custom decoder with fallback values for optional API fields
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Decode required fields with fallbacks for safety
        id = try container.decode(String.self, forKey: .id)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Unknown Zone"
        number = try container.decodeIfPresent(String.self, forKey: .number) ?? ""
        operator_id = try container.decodeIfPresent(String.self, forKey: .operator_id) ?? ""
    }
    
    /// Maps JSON keys from API response to Swift properties
    enum CodingKeys: String, CodingKey {
        case id, name, number, operator_id
    }
    
    /// Manual initializer for creating Zone instances programmatically
    init(id: String, name: String, number: String, operator_id: String) {
        self.id = id
        self.name = name
        self.number = number
        self.operator_id = operator_id
    }
}

/// SwiftData model representing a parking operator.
/// Operators are organizations that manage parking zones (e.g., city parking authority).
/// Synced to CloudKit for cross-device access.
@Model
class Operator: Identifiable {
    var id: String = ""
    var name: String = ""
    var environment: OperatorEnvironment?
    var dateCreated: Date = Date()
    
    /// Creates a new operator. The ID should match the operator's UUID in the Passport API.
    init(name: String, id: String? = nil, environment: OperatorEnvironment = .production) {
        self.id = id ?? UUID().uuidString
        self.name = name
        self.environment = environment
        self.dateCreated = Date()
        print("Creating a new operator: \(self.name) - ID: \(self.id)")
    }
    
    // Convenience initializer for UUID compatibility
    init(name: String, uuid: UUID, environment: OperatorEnvironment = .production) {
        self.id = uuid.uuidString
        self.name = name
        self.environment = environment
        self.dateCreated = Date()
        print("Creating a new operator: \(self.name) - ID: \(self.id)")
    }
}
