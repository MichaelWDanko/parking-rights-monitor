//
//  ParkingRightListViewModel.swift
//  PassportAPIExplorer
//
//  Created by Michael Danko on 11/1/25.
//

import Foundation

extension ParkingRightListView {
    
    @Observable
    class ParkingRightListViewModel {
        
        var parkingRights: [ParkingRight] = []
        var isLoadingRights: Bool = false
        var rightsError: String?
        
        private let passportAPIService: PassportAPIService
        private let selectedOperatorId: String
        private let selectedZone: Zone
        
        var searchText: String = ""
    
        init(passportAPIService: PassportAPIService, op: String, z: Zone) {
            self.passportAPIService = passportAPIService
            self.selectedOperatorId = op
            self.selectedZone = z
        }
        
        var filteredRights: [ParkingRight] {
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
        
        func loadParkingRights() {
            print("🚗 Starting to load parking rights for zone: \(selectedZone.name) (ID: \(selectedZone.id))")
            isLoadingRights = true
            rightsError = nil
            
            Task {
                do {
                    print("🚗 Calling API service to fetch parking rights...")
                    let fetchedRights = try await passportAPIService.fetchParkingRights(
                        forOperatorId: selectedOperatorId,
                        zoneId: selectedZone.id
                    )
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
    
}
