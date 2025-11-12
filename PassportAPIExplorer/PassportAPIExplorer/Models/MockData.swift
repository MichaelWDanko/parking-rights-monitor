//
//  MockData.swift
//  Passport API Explorer
//
//  Created by Michael Danko on 10/6/25.
//

import Foundation

// Default zDanko Parking operators for all environments
let zdanko = Operator(name: "zDanko Parking", id: "43c401c0-a17e-40e5-ae26-4f5f205bf063", environment: .production)
let zdankoStaging = Operator(name: "zDanko Parking (Staging)", id: "20c33f62-29e5-4e38-a107-0c287d0fd823", environment: .staging)
let zdankoDev = Operator(name: "zDanko Parking (Dev)", id: "5e0a5b4b-05dd-4007-811d-b2ddfba268f4", environment: .development)

var mockOperators: [Operator] = [zdanko, zdankoStaging, zdankoDev]

let right = ParkingRight(
    id: "0800fc577294c34e0b28ad2839435945",
    operatorId: "6c90fda7-e2cf-4d54-ae7c-9a3e47e09c01",
    zoneId: "64b64b7e-6f9c-446c-a0b7-72723a6321a0",
    type: "parking",
    startTime: "2025-04-01 10:00:00Z",
    endTime: "2025-04-01 16:27:00Z",
    vehicle: Vehicle(vehiclePlate: "ABC123", vehicleState: "SC"),
    referenceId: "00001111",
    spaceNumber: "5"
)
