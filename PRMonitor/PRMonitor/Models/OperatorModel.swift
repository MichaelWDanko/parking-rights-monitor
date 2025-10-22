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
    let operator_id: UUID
}

struct Operator: Identifiable, Codable {
    let id: UUID
    let name: String
    
    let environment: Environment
    
    var zones = [Zone]()
    
    init(name: String) {
        self.id = UUID()
        self.environment = .production
        self.name = name
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
