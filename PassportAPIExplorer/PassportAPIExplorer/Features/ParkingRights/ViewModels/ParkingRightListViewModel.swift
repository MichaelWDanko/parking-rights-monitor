//
//  ParkingRightListViewModel.swift
//  PassportAPIExplorer
//
//  Created by Michael Danko on 11/1/25.
//

import Foundation

enum SearchMode: String, CaseIterable {
    case zoneBased = "By Zone"
    case spaceVehicleBased = "By Space/Vehicle"
}

@Observable
class ParkingRightListViewModel {
    
    var parkingRights: [ParkingRight] = []
    var isLoadingRights: Bool = false
    var rightsError: String?
    
    private let passportAPIService: PassportAPIService
    private let selectedOperatorId: String
    private let selectedZone: Zone?
    
    var searchMode: SearchMode = .zoneBased
    var searchText: String = ""
    var spaceNumber: String = ""
    var vehiclePlate: String = ""
    var vehicleState: String = ""

    init(passportAPIService: PassportAPIService, op: String, z: Zone?) {
        self.passportAPIService = passportAPIService
        self.selectedOperatorId = op
        self.selectedZone = z
        // Set default search mode based on whether zone is provided
        if z == nil {
            self.searchMode = .spaceVehicleBased
        }
    }
    
    var filteredRights: [ParkingRight] {
        // For space/vehicle mode, show API results directly (no local filtering)
        if searchMode == .spaceVehicleBased {
            return parkingRights
        }
        
        // For zone-based mode, apply local filtering
        if searchText.isEmpty {
            return parkingRights
        } else {
            return parkingRights.filter { parkingRight in
                parkingRight.vehicle_plate?.localizedCaseInsensitiveContains(searchText) == true ||
                parkingRight.space_number?.localizedCaseInsensitiveContains(searchText) == true ||
                parkingRight.vehicle_state?.localizedCaseInsensitiveContains(searchText) == true ||
                parkingRight.reference_id?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
    }
    
    var canSearch: Bool {
        switch searchMode {
        case .zoneBased:
            // Zone-based mode always allows searching (zone is already selected)
            return true
        case .spaceVehicleBased:
            // At least one space/vehicle field must be filled
            return !spaceNumber.trimmingCharacters(in: .whitespaces).isEmpty ||
                   !vehiclePlate.trimmingCharacters(in: .whitespaces).isEmpty ||
                   !vehicleState.trimmingCharacters(in: .whitespaces).isEmpty
        }
    }
    
    func loadParkingRights() {
        isLoadingRights = true
        rightsError = nil
        
        Task {
            do {
                let fetchedRights: [ParkingRight]
                
                switch searchMode {
                case .zoneBased:
                    guard let zone = selectedZone else {
                        await MainActor.run {
                            rightsError = "Zone is required for zone-based search"
                            isLoadingRights = false
                        }
                        return
                    }
                    print("🚗 Starting to load parking rights for zone: \(zone.name) (ID: \(zone.id))")
                    print("🚗 Calling API service to fetch parking rights...")
                    fetchedRights = try await passportAPIService.fetchParkingRights(
                        forOperatorId: selectedOperatorId,
                        zoneId: zone.id
                    )
                    
                case .spaceVehicleBased:
                    // Validate that at least one field is filled
                    guard canSearch else {
                        await MainActor.run {
                            rightsError = "Please provide at least one search criteria (space number, vehicle plate, or vehicle state)"
                            isLoadingRights = false
                        }
                        return
                    }
                    print("🚗 Starting to load parking rights for operator: \(selectedOperatorId)")
                    print("🚗 Search criteria - Space: \(spaceNumber), Plate: \(vehiclePlate), State: \(vehicleState)")
                    print("🚗 Calling API service to fetch parking rights...")
                    fetchedRights = try await passportAPIService.fetchParkingRights(
                        forOperatorId: selectedOperatorId,
                        zoneId: nil,
                        spaceNumber: spaceNumber.trimmingCharacters(in: .whitespaces).isEmpty ? nil : spaceNumber,
                        vehiclePlate: vehiclePlate.trimmingCharacters(in: .whitespaces).isEmpty ? nil : vehiclePlate,
                        vehicleState: vehicleState.trimmingCharacters(in: .whitespaces).isEmpty ? nil : vehicleState
                    )
                }
                
                print("🚗 API service returned \(fetchedRights.count) parking rights")
                for (index, right) in fetchedRights.enumerated() {
                    print("🚗 Parking Right \(index + 1): \(right.id)")
                    print("🚗   - Vehicle: \(right.vehicle_plate ?? "N/A") (\(right.vehicle_state ?? "N/A"))")
                    print("🚗   - Time: \(right.start_time) to \(right.end_time)")
                    print("🚗   - Reference: \(right.reference_id ?? "N/A")")
                }
                await MainActor.run {
                    parkingRights = fetchedRights
                    isLoadingRights = false
                    print("🚗 Updated parkingRights array with \(parkingRights.count) items")
                }
            } catch {
                print("🚗 Error loading parking rights: \(error)")
                await MainActor.run {
                    rightsError = error.localizedDescription
                    isLoadingRights = false
                }
            }
        }
    }
}
