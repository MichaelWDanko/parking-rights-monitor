//
//  StopSessionFormView.swift
//  Passport API Explorer
//
//  Created by Michael Danko on 10/30/25.
//

import SwiftUI
import SwiftData

/// Form view for stopping an existing parking session.
struct StopSessionFormView: View {
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
                LabeledContent("Started", value: session.startTime, format: .dateTime)
                    .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
            }
            .listRowBackground(Color.glassBackground)
            
            Section(header: FormSectionHeader(title: "Actual End Time")) {
                DatePicker("End Time", selection: $formViewModel.newEndTime)
            }
            .listRowBackground(Color.glassBackground)
            
            Section(header: FormSectionHeader(title: "Stop Event Fees")) {
                Text("Can be negative for refunds")
                    .font(.caption)
                    .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
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
        StopSessionFormView(session: mockSession, formViewModel: formVM)
            .navigationTitle("Stop Session")
            .adaptiveGlassmorphismBackground()
    }
    .modelContainer(container)
}

