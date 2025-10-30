//
//  OperatorModel.swift
//  Passport API Explorer
//
//  Created by Michael Danko on 10/5/25.
//

import Foundation
import SwiftData

enum OperatorEnvironment : String, Codable, CaseIterable {
    case production
    case staging
    case development
}

struct Zone : Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let number: String
    let operator_id: String
    
    // Custom initializer to handle API response safely
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Decode required fields with fallbacks for safety
        id = try container.decode(String.self, forKey: .id)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Unknown Zone"
        number = try container.decodeIfPresent(String.self, forKey: .number) ?? ""
        operator_id = try container.decodeIfPresent(String.self, forKey: .operator_id) ?? ""
    }
    
    // Custom coding keys for the fields we need
    enum CodingKeys: String, CodingKey {
        case id, name, number, operator_id
    }
    
    // Custom initializer for creating Zone instances manually
    init(id: String, name: String, number: String, operator_id: String) {
        self.id = id
        self.name = name
        self.number = number
        self.operator_id = operator_id
    }
}

@Model
class Operator: Identifiable {
    var id: String = ""
    var name: String = ""
    var environment: OperatorEnvironment?
    var dateCreated: Date = Date()
    
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
