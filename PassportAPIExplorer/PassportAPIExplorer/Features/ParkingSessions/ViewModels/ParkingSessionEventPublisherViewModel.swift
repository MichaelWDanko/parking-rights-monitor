//
//  ParkingSessionEventPublisherViewModel.swift
//  Passport API Explorer
//
//  Created by Michael Danko on 10/30/25.
//

import Foundation
import Observation

@Observable
@MainActor
final class ParkingSessionEventPublisherViewModel {
    var isLoading = false
    var errorMessage: String?
    var successMessage: String?
    
    private let apiService: PassportAPIService
    private let listViewModel: ParkingSessionsListViewModel
    
    init(apiService: PassportAPIService, listViewModel: ParkingSessionsListViewModel) {
        self.apiService = apiService
        self.listViewModel = listViewModel
    }
    
    // MARK: - Event Publishing
    
    func publishStartedEvent(
        sessionId: String? = nil,
        operatorId: String,
        zoneIdType: ZoneIDType,
        zoneId: String,
        zoneName: String? = nil,
        vehiclePlate: String,
        vehicleState: String,
        vehicleCountry: String,
        spaceNumber: String?,
        startTime: Date,
        endTime: Date,
        accountId: String?,
        eventFees: EventFees,
        rateName: String?,
        locationDetails: LocationDetails?,
        payment: Payment?
    ) async throws {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        defer { isLoading = false }
        
        // Use provided session ID or generate new one
        let finalSessionId = sessionId ?? ParkingSession.generateSessionId()
        let occurredAt = Date()
        
        let vehicle = EventVehicle(
            vehiclePlate: vehiclePlate,
            vehicleState: vehicleState,
            vehicleCountry: vehicleCountry.isEmpty ? nil : vehicleCountry
        )
        
        let eventData = ParkingSessionStartedData(
            occurredAt: occurredAt.toISO8601String(),
            sessionId: finalSessionId,
            operatorId: operatorId,
            passportZoneId: zoneIdType == .passport ? zoneId : nil,
            externalZoneId: zoneIdType == .external ? zoneId : nil,
            startTime: startTime.toISO8601String(),
            endTime: endTime.toISO8601String(),
            accountId: accountId,
            vehicle: vehicle,
            spaceNumber: spaceNumber,
            eventFees: eventFees,
            rateName: rateName,
            locationDetails: locationDetails,
            payment: payment
        )
        
        do {
            let success = try await apiService.publishParkingSessionEvent(
                type: ParkingSessionEventType.started.rawValue,
                version: "3.0.0",
                data: [eventData]
            )
            
            if success {
                // Save session locally after successful API call with the same session ID
                listViewModel.createSession(
                    sessionId: finalSessionId,
                    operatorId: operatorId,
                    zoneIdType: zoneIdType,
                    zoneId: zoneId,
                    zoneName: zoneName,
                    vehiclePlate: vehiclePlate,
                    vehicleState: vehicleState,
                    vehicleCountry: vehicleCountry,
                    spaceNumber: spaceNumber,
                    startTime: startTime,
                    endTime: endTime
                )
                successMessage = "Parking session started successfully!"
            } else {
                errorMessage = "Failed to publish started event"
            }
        } catch {
            errorMessage = "Error publishing started event: \(error.localizedDescription)"
            throw error
        }
    }
    
    func publishExtendedEvent(
        session: ParkingSession,
        newEndTime: Date,
        eventFees: EventFees,
        totalSessionFees: EventFees,
        accountId: String?,
        rateName: String?,
        locationDetails: LocationDetails?,
        payment: Payment?
    ) async throws {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        defer { isLoading = false }
        
        let occurredAt = Date()
        let vehicle = EventVehicle(
            vehiclePlate: session.vehiclePlate,
            vehicleState: session.vehicleState,
            vehicleCountry: session.vehicleCountry.isEmpty ? nil : session.vehicleCountry
        )
        
        let eventData = ParkingSessionExtendedData(
            occurredAt: occurredAt.toISO8601String(),
            sessionId: session.sessionId,
            operatorId: session.operatorId,
            passportZoneId: session.computedZoneIdType == .passport ? session.zoneId : nil,
            externalZoneId: session.computedZoneIdType == .external ? session.zoneId : nil,
            startTime: session.startTime.toISO8601String(),
            endTime: newEndTime.toISO8601String(),
            accountId: accountId,
            vehicle: vehicle,
            spaceNumber: session.spaceNumber,
            eventFees: eventFees,
            totalSessionFees: totalSessionFees,
            rateName: rateName,
            locationDetails: locationDetails,
            payment: payment
        )
        
        do {
            let success = try await apiService.publishParkingSessionEvent(
                type: ParkingSessionEventType.extended.rawValue,
                version: "3.0.0",
                data: [eventData]
            )
            
            if success {
                // Update session locally after successful API call
                listViewModel.updateSession(session, newEndTime: newEndTime)
                successMessage = "Parking session extended successfully!"
            } else {
                errorMessage = "Failed to publish extended event"
            }
        } catch {
            errorMessage = "Error publishing extended event: \(error.localizedDescription)"
            throw error
        }
    }
    
    func publishStoppedEvent(
        session: ParkingSession,
        endTime: Date,
        eventFees: EventFees,
        totalSessionFees: EventFees,
        accountId: String?,
        rateName: String?,
        locationDetails: LocationDetails?,
        payment: Payment?
    ) async throws {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        defer { isLoading = false }
        
        let occurredAt = Date()
        let vehicle = EventVehicle(
            vehiclePlate: session.vehiclePlate,
            vehicleState: session.vehicleState,
            vehicleCountry: session.vehicleCountry.isEmpty ? nil : session.vehicleCountry
        )
        
        let eventData = ParkingSessionStoppedData(
            occurredAt: occurredAt.toISO8601String(),
            sessionId: session.sessionId,
            operatorId: session.operatorId,
            passportZoneId: session.computedZoneIdType == .passport ? session.zoneId : nil,
            externalZoneId: session.computedZoneIdType == .external ? session.zoneId : nil,
            startTime: session.startTime.toISO8601String(),
            endTime: endTime.toISO8601String(),
            accountId: accountId,
            vehicle: vehicle,
            spaceNumber: session.spaceNumber,
            eventFees: eventFees,
            totalSessionFees: totalSessionFees,
            rateName: rateName,
            locationDetails: locationDetails,
            payment: payment
        )
        
        do {
            let success = try await apiService.publishParkingSessionEvent(
                type: ParkingSessionEventType.stopped.rawValue,
                version: "3.0.0",
                data: [eventData]
            )
            
            if success {
                // Stop session locally after successful API call
                listViewModel.stopSession(session)
                successMessage = "Parking session stopped successfully!"
            } else {
                errorMessage = "Failed to publish stopped event"
            }
        } catch {
            errorMessage = "Error publishing stopped event: \(error.localizedDescription)"
            throw error
        }
    }
    
    // MARK: - Helper Methods
    
    func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }
}

