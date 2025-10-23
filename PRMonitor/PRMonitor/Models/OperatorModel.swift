//
//  OperatorModel.swift
//  PRMonitor
//
//  Created by Michael Danko on 10/5/25.
//

import Foundation

enum Environment : String, Codable {
    case production
    case staging
    case development
}

struct Zone : Identifiable, Codable {
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

struct Operator: Identifiable, Codable {
    let id: UUID
    let name: String
    let environment: Environment
    
    init(name: String) {
        self.id = UUID()
        self.name = name
        self.environment = .production
        print("Creating a new operator: \(self.name) - \(self.id)")
    }
    
    init(id: UUID, name: String) {
        self.id = id
        self.name = name
        self.environment = .production
    }

    init(id: UUID, name: String, environment: Environment) {
        self.id = id
        self.name = name
        self.environment = environment
    }
}
