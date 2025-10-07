//
//  MockData.swift
//  PRMonitor
//
//  Created by Michael Danko on 10/6/25.
//

import Foundation

let pleasantville = Operator(id: UUID(uuidString: "12a11eb2-6828-43a3-ba73-c11e1bc0c4a2")!, name: "City of Pleasantville")
let zdanko = Operator(id: UUID(uuidString: "581877df-3876-4700-9527-34db71ce1cab")!, name: "zDanko Parking")
let charlotte = Operator(id: UUID(uuidString: "910abd15-abae-4810-9787-76665bdd79e0")!, name: "City of Charlotte, NC")

var mockOperators: [Operator] = {
    var p = pleasantville
    p.zones = [
        Zone(id: UUID(uuidString: "e0a1b2c3-0001-4d5e-8a01-000000000101")!, name: "Downtown Core", number: "P-101", operator_id: p.id),
        Zone(id: UUID(uuidString: "e0a1b2c3-0002-4d5e-8a01-000000000102")!, name: "Riverfront", number: "P-102", operator_id: p.id),
        Zone(id: UUID(uuidString: "e0a1b2c3-0003-4d5e-8a01-000000000103")!, name: "Uptown", number: "P-103", operator_id: p.id),
        Zone(id: UUID(uuidString: "e0a1b2c3-0004-4d5e-8a01-000000000104")!, name: "College District", number: "P-104", operator_id: p.id)
    ]

    var z = zdanko
    z.zones = [
        Zone(id: UUID(uuidString: "f1b2c3d4-1001-4a6b-8b02-000000000201")!, name: "Lot A", number: "Z-201", operator_id: z.id),
        Zone(id: UUID(uuidString: "f1b2c3d4-1002-4a6b-8b02-000000000202")!, name: "Lot B", number: "Z-202", operator_id: z.id),
        Zone(id: UUID(uuidString: "f1b2c3d4-1003-4a6b-8b02-000000000203")!, name: "Garage 1", number: "Z-203", operator_id: z.id),
        Zone(id: UUID(uuidString: "f1b2c3d4-1004-4a6b-8b02-000000000204")!, name: "Garage 2", number: "Z-204", operator_id: z.id)
    ]

    var c = charlotte
    c.zones = [
        Zone(id: UUID(uuidString: "a2c3d4e5-2001-4b7c-8c03-000000000301")!, name: "Uptown Core", number: "C-301", operator_id: c.id),
        Zone(id: UUID(uuidString: "a2c3d4e5-2002-4b7c-8c03-000000000302")!, name: "South End", number: "C-302", operator_id: c.id),
        Zone(id: UUID(uuidString: "a2c3d4e5-2003-4b7c-8c03-000000000303")!, name: "NoDa", number: "C-303", operator_id: c.id),
        Zone(id: UUID(uuidString: "a2c3d4e5-2004-4b7c-8c03-000000000304")!, name: "Plaza Midwood", number: "C-304", operator_id: c.id)
    ]

    return [p, z, c]
}()
