//
//  MockData.swift
//  Passport API Explorer
//
//  Created by Michael Danko on 10/6/25.
//

import Foundation

// let pleasantville = Operator(name: "City of Pleasantville", id: "12a11eb2-6828-43a3-ba73-c11e1bc0c4a2")
let zdanko = Operator(name: "zDanko Parking", id: "43c401c0-a17e-40e5-ae26-4f5f205bf063")
// let charlotte = Operator(name: "City of Charlotte, NC", id: "910abd15-abae-4810-9787-76665bdd79e0")

var mockOperators: [Operator] = [zdanko]

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
