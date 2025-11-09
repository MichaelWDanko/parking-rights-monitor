//
//  ParkingSessionEventFormViewModel.swift
//  Passport API Explorer
//
//  Created by Michael Danko on 10/30/25.
//

import Foundation
import Observation
import SwiftData

/// ViewModel managing form state for creating/editing parking session events.
/// Handles form validation, zone loading, and submission logic (MVVM pattern).
/// Separates UI state from business logic for testability and maintainability.
@Observable
@MainActor
final class ParkingSessionEventFormViewModel {
    // MARK: - Form State Properties
    
    // Session ID
    var previewSessionId: String = ParkingSession.generateSessionId()
    
    // Operator and Zone
    var selectedOperator: Operator?
    var useExternalZoneId = false
    var availableZones: [Zone] = []
    var selectedZone: Zone?
    var externalZoneId = ""
    var isLoadingZones = false
    var sortOption: SortOption = .numberAscending
    
    // Vehicle Information
    var vehiclePlate = ""
    var vehicleState = ""
    var vehicleCountry = "US"
    var spaceNumber = ""
    
    // Session Times
    var startTime = Date()
    var endTime = Date().addingTimeInterval(3600)
    
    // Fees
    var parkingFee = "1.25"
    var convenienceFee = "0.25"
    var tax = "0.10"
    var currencyCode = "USD"
    
    // Optional Fields
    var accountId = ""
    var rateName = ""
    
    // Extend/Stop Session Fields
    var newEndTime = Date()
    var totalParkingFee = "2.50"
    var totalConvenienceFee = "0.50"
    var totalTax = "0.20"
    
    // MARK: - Dependencies
    
    private let apiService: PassportAPIService
    private let eventPublisher: ParkingSessionEventPublisherViewModel
    
    // MARK: - Initialization
    
    init(apiService: PassportAPIService, eventPublisher: ParkingSessionEventPublisherViewModel) {
        self.apiService = apiService
        self.eventPublisher = eventPublisher
    }
    
    // MARK: - Computed Properties
    
    /// Returns zones sorted according to the current sortOption.
    var sortedZones: [Zone] {
        sortZones(availableZones)
    }
    
    /// Validates that all required form fields are filled and end time is after start time.
    /// Used to enable/disable the submit button in the UI.
    var isStartFormValid: Bool {
        guard selectedOperator != nil else { return false }
        
        // Zone validation: either external zone ID or Passport zone must be selected
        let hasValidZone = useExternalZoneId ? !externalZoneId.isEmpty : selectedZone != nil
        
        return hasValidZone &&
        !vehiclePlate.isEmpty &&
        !vehicleState.isEmpty &&
        !parkingFee.isEmpty &&
        !convenienceFee.isEmpty &&
        !tax.isEmpty &&
        !currencyCode.isEmpty &&
        endTime > startTime
    }
    
    // MARK: - Private Helpers
    
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
    
    // MARK: - Actions
    
    func generateNewSessionId() {
        previewSessionId = ParkingSession.generateSessionId()
    }
    
    func generateRandomVehicle() {
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        let numbers = "0123456789"
        
        // Generate random plate (3 letters + 4 numbers)
        let randomLetters = String((0..<3).map { _ in letters.randomElement()! })
        let randomNumbers = String((0..<4).map { _ in numbers.randomElement()! })
        vehiclePlate = randomLetters + randomNumbers
        
        // Random US state
        let states = ["CA", "NY", "TX", "FL", "IL", "PA", "OH", "GA", "NC", "MI",
                      "NJ", "VA", "WA", "AZ", "MA", "TN", "IN", "MO", "MD", "WI",
                      "CO", "MN", "SC", "AL", "LA", "KY", "OR", "OK", "CT", "UT"]
        vehicleState = states.randomElement()!
        
        vehicleCountry = "US"
        
        // Random space number (optional, 50% chance) - integer between 1-50
        if Bool.random() {
            spaceNumber = String(Int.random(in: 1...50))
        } else {
            spaceNumber = ""
        }
    }
    
    func generateRandomFees() {
        // Generate realistic parking fees
        let parkingAmounts = ["0.50", "1.00", "1.25", "1.50", "2.00", "2.50", "3.00", "4.00", "5.00"]
        parkingFee = parkingAmounts.randomElement()!
        
        // Convenience fee typically 10-20% of parking or fixed small amount
        let convenienceAmounts = ["0.25", "0.35", "0.50", "0.75"]
        convenienceFee = convenienceAmounts.randomElement()!
        
        // Tax typically small percentage
        let taxAmounts = ["0.10", "0.15", "0.20", "0.25", "0.30"]
        tax = taxAmounts.randomElement()!
        
        currencyCode = "USD"
    }
    
    /// Fetches zones for the selected operator from the API.
    /// Called when operator selection changes to populate the zone picker.
    func loadZonesForOperator(_ op: Operator) {
        Task {
            isLoadingZones = true
            do {
                // API call to fetch zones: GET /v3/shared/zones?operator_id={id}
                availableZones = try await apiService.fetchZones(forOperatorId: op.id)
            } catch {
                print("Failed to load zones: \(error)")
                availableZones = []
            }
            isLoadingZones = false
        }
    }
    
    func handleOperatorChange(_ newOperator: Operator?) {
        if let op = newOperator {
            loadZonesForOperator(op)
        } else {
            availableZones = []
            selectedZone = nil
        }
    }
    
    func handleExternalZoneToggle(_ isOn: Bool) {
        if isOn {
            selectedZone = nil
            externalZoneId = ""
        }
    }
    
    func setQuickDuration(_ seconds: TimeInterval) {
        endTime = startTime.addingTimeInterval(seconds)
    }
    
    /// Submits the start session form by publishing a parking_session_started event.
    /// Builds the event payload from form fields and calls the API via the publisher ViewModel.
    func submitStartSession() async throws {
        guard let op = selectedOperator else { return }
        
        // Determine zone ID type and value based on user's selection
        let operatorId = op.id
        let zoneIdType: ZoneIDType = useExternalZoneId ? .external : .passport
        let zoneId: String = useExternalZoneId ? externalZoneId : (selectedZone?.id ?? "")
        let zoneName: String? = useExternalZoneId ? nil : selectedZone?.name
        
        // Build fee structure from form inputs
        let fees = EventFees(
            parkingFee: parkingFee,
            convenienceFee: convenienceFee,
            tax: tax,
            currencyCode: currencyCode
        )
        
        // Delegate to publisher ViewModel to handle API call
        try await eventPublisher.publishStartedEvent(
            sessionId: previewSessionId,
            operatorId: operatorId,
            zoneIdType: zoneIdType,
            zoneId: zoneId,
            zoneName: zoneName,
            vehiclePlate: vehiclePlate,
            vehicleState: vehicleState,
            vehicleCountry: vehicleCountry,
            spaceNumber: spaceNumber.isEmpty ? nil : spaceNumber,
            startTime: startTime,
            endTime: endTime,
            accountId: accountId.isEmpty ? nil : accountId,
            eventFees: fees,
            rateName: rateName.isEmpty ? nil : rateName,
            locationDetails: nil,
            payment: nil
        )
        
        clearStartForm()
        // Generate new session ID for next session
        previewSessionId = ParkingSession.generateSessionId()
    }
    
    func submitExtendSession(_ session: ParkingSession) async throws {
        let fees = EventFees(parkingFee: parkingFee, convenienceFee: convenienceFee, tax: tax, currencyCode: currencyCode)
        let totalFees = EventFees(parkingFee: totalParkingFee, convenienceFee: totalConvenienceFee, tax: totalTax, currencyCode: currencyCode)
        
        try await eventPublisher.publishExtendedEvent(
            session: session,
            newEndTime: newEndTime,
            eventFees: fees,
            totalSessionFees: totalFees,
            accountId: accountId.isEmpty ? nil : accountId,
            rateName: rateName.isEmpty ? nil : rateName,
            locationDetails: nil,
            payment: nil
        )
    }
    
    func submitStopSession(_ session: ParkingSession) async throws {
        let fees = EventFees(parkingFee: parkingFee, convenienceFee: convenienceFee, tax: tax, currencyCode: currencyCode)
        let totalFees = EventFees(parkingFee: totalParkingFee, convenienceFee: totalConvenienceFee, tax: totalTax, currencyCode: currencyCode)
        
        try await eventPublisher.publishStoppedEvent(
            session: session,
            endTime: newEndTime,
            eventFees: fees,
            totalSessionFees: totalFees,
            accountId: accountId.isEmpty ? nil : accountId,
            rateName: rateName.isEmpty ? nil : rateName,
            locationDetails: nil,
            payment: nil
        )
    }
    
    func clearStartForm() {
        selectedOperator = nil
        selectedZone = nil
        externalZoneId = ""
        availableZones = []
        useExternalZoneId = false
        vehiclePlate = ""
        vehicleState = ""
        vehicleCountry = "US"
        spaceNumber = ""
        startTime = Date()
        endTime = Date().addingTimeInterval(3600)
        accountId = ""
        parkingFee = "1.25"
        convenienceFee = "0.25"
        tax = "0.10"
        currencyCode = "USD"
        rateName = ""
    }
}

