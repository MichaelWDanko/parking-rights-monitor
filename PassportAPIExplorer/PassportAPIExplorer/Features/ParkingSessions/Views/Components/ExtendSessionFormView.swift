//
//  ExtendSessionFormView.swift
//  Passport API Explorer
//
//  Created by Michael Danko on 10/30/25.
//

import SwiftUI
import SwiftData

/// Form view for extending an existing parking session.
struct ExtendSessionFormView: View {
    let session: ParkingSession
    @Bindable var formViewModel: ParkingSessionEventFormViewModel
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Form {
            Section(header: FormSectionHeader(title: "Session Details")) {
                LabeledContent("Vehicle", value: "\(session.vehiclePlate) (\(session.vehicleState))")
                    .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                LabeledContent("Zone", value: session.zoneId)
                    .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                LabeledContent("Current End", value: session.endTime, format: .dateTime)
                    .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
            }
            .listRowBackground(Color.glassBackground)
            
            Section(header: FormSectionHeader(title: "New End Time")) {
                DatePicker("End Time", selection: $formViewModel.newEndTime)
            }
            .listRowBackground(Color.glassBackground)
            
            Section(header: FormSectionHeader(title: "Extension Fees")) {
                FeesInputFields(
                    parkingFee: $formViewModel.parkingFee,
                    convenienceFee: $formViewModel.convenienceFee,
                    tax: $formViewModel.tax,
                    currencyCode: $formViewModel.currencyCode,
                    showRandomButton: false,
                    showCurrencyCode: false,
                    showHeader: false
                )
            }
            
            TotalFeesInputFields(
                totalParkingFee: $formViewModel.totalParkingFee,
                totalConvenienceFee: $formViewModel.totalConvenienceFee,
                totalTax: $formViewModel.totalTax
            )
            
            // Padding for button
            Section {
                Color.clear.frame(height: 80).listRowBackground(Color.clear)
            }
        }
        .scrollContentBackground(.hidden)
    }
}

#Preview {
    let mockSession = ParkingSession(
        operatorId: "test-op",
        zoneId: "test-zone",
        vehiclePlate: "ABC1234",
        vehicleState: "CA",
        endTime: Date().addingTimeInterval(3600)
    )
    
    let container = try! ModelContainer(
        for: ParkingSession.self, Operator.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let service = PreviewEnvironment.makePreviewService()
    let listVM = ParkingSessionsListViewModel(modelContext: container.mainContext)
    let publisher = ParkingSessionEventPublisherViewModel(apiService: service, listViewModel: listVM)
    let formVM = ParkingSessionEventFormViewModel(apiService: service, eventPublisher: publisher)
    
    NavigationStack {
        ExtendSessionFormView(session: mockSession, formViewModel: formVM)
            .navigationTitle("Extend Session")
            .adaptiveGlassmorphismBackground()
    }
    .modelContainer(container)
}

