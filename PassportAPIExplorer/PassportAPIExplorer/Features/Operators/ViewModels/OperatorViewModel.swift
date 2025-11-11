//
//  OperatorViewModel.swift
//  Passport API Explorer
//
//  Created by Michael Danko on 10/22/25.
//

import Foundation
import SwiftUI

enum SortOption: String, CaseIterable {
    case nameAscending = "A-Z by Name"
    case nameDescending = "Z-A by Name"
    case numberAscending = "ASC by Number"
    case numberDescending = "DESC by Number"
}

extension OperatorZoneView {
    @Observable
    class OperatorViewModel {
        var zones: [Zone] = []
        var isLoadingZones = false
        var zonesError: String?
        var searchText: String = ""
        var sortOption: SortOption = .numberAscending
        
        private let selectedOperator: Operator
        private let apiServiceManager: APIServiceManager
        
        init(selectedOperator: Operator, apiServiceManager: APIServiceManager) {
            self.selectedOperator = selectedOperator
            self.apiServiceManager = apiServiceManager
        }
        
        private var passportAPIService: PassportAPIService? {
            return apiServiceManager.service(forOperator: selectedOperator)
        }
        
        var filteredZones: [Zone] {
            let filtered = searchText.isEmpty ? zones : zones.filter { zone in
                zone.name.localizedCaseInsensitiveContains(searchText) ||
                zone.number.localizedCaseInsensitiveContains(searchText)
            }
            
            return sortZones(filtered)
        }
        
        private func sortZones(_ zones: [Zone]) -> [Zone] {
            switch sortOption {
            case .nameAscending:
                return zones.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            case .nameDescending:
                return zones.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedDescending }
            case .numberAscending:
                return zones.sorted { $0.number.localizedCaseInsensitiveCompare($1.number) == .orderedAscending }
            case .numberDescending:
                return zones.sorted { $0.number.localizedCaseInsensitiveCompare($1.number) == .orderedDescending }
            }
        }
        
        func loadZones() {
            print("🔄 Starting to load zones for operator: \(selectedOperator.name) (ID: \(selectedOperator.id))")
            isLoadingZones = true
            zonesError = nil
            
            Task {
                do {
                    print("🔄 Calling API service to fetch zones...")
                    let fetchedZones = try await passportAPIService?.fetchZones(forOperatorId: selectedOperator.id)
                    print("🔄 API service returned \(fetchedZones?.count ?? 0) zones")
                    zones = fetchedZones ?? []
                    print("🔄 ViewModel now has \(zones.count) zones")
                    isLoadingZones = false
                } catch {
                    print("🔄 Error loading zones: \(error)")
                    zonesError = error.localizedDescription
                    isLoadingZones = false
                }
            }
        }
    }
}

