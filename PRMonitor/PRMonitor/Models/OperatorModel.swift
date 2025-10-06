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

struct Operator: Identifiable, Codable {
    let id: UUID
    let name: String
    
    let environment: Environment
    
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

let pleasantville = Operator(name: "City of Pleasantville")
let zdanko = Operator(name: "zDanko Parking")
let charlotte = Operator(name: "City of Charlotte, NC")

var mockOperators: [Operator] = [pleasantville, zdanko, charlotte]


