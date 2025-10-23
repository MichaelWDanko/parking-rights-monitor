//
//  OperatorViewModel.swift
//  PRMonitor
//
//  Created by Michael Danko on 10/22/25.
//

import Foundation
import SwiftUI


extension OperatorView {
    @Observable
    class OperatorViewModel {
        var zones: [Zone] = []
        var isLoadingZones = false
        var zonesError: String?
        var searchText: String = ""
        
        private let selectedOperator: Operator
        private var passportAPIService: PassportAPIService?
        
        init(selectedOperator: Operator, passportAPIService: PassportAPIService) {
            self.selectedOperator = selectedOperator
            self.passportAPIService = passportAPIService
        }
        
        var filteredZones: [Zone] {
            if searchText.isEmpty {
                return zones
            } else {
                return zones.filter { zone in
                    zone.name.localizedCaseInsensitiveContains(searchText) ||
                    zone.number.localizedCaseInsensitiveContains(searchText)
                }
            }
        }
        
        func loadZones() {
            print("🔄 Starting to load zones for operator: \(selectedOperator.name) (ID: \(selectedOperator.id))")
            isLoadingZones = true
            zonesError = nil
            
            Task {
                do {
                    print("🔄 Calling API service to fetch zones...")
                    let fetchedZones = try await passportAPIService?.fetchZones(forOperatorId: selectedOperator.id.uuidString)
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

