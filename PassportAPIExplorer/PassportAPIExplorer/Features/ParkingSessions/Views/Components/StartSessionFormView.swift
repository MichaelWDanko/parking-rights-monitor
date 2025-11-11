//
//  StartSessionFormView.swift
//  Passport API Explorer
//
//  Created by Michael Danko on 10/30/25.
//

import SwiftUI
import SwiftData

/// Form view for starting a new parking session.
struct StartSessionFormView: View {
    @Bindable var formViewModel: ParkingSessionEventFormViewModel
    @Query private var operators: [Operator]
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Form {
            // Session ID Preview Section
            Section {
                HStack {
                    Text("Session ID Preview")
                        .font(.headline)
                        .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
                    Spacer()
                    Button(action: { formViewModel.generateNewSessionId() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.clockwise.circle.fill")
                            Text("New ID")
                        }
                        .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .tint(Color.adaptiveCyanAccent(colorScheme == .dark))
                    .controlSize(.small)
                }
                
                HStack {
                    Text(formViewModel.previewSessionId)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(Color.adaptiveCyanAccent(colorScheme == .dark))
                    Spacer()
                    Button(action: {
                        UIPasteboard.general.string = formViewModel.previewSessionId
                    }) {
                        Image(systemName: "doc.on.doc")
                            .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                    }
                    .buttonStyle(.borderless)
                }
            }
            .listRowBackground(Color.glassBackground)
            
            // Operator Section
            Section(header: FormSectionHeader(title: "Operator")) {
                if operators.isEmpty {
                    Text("No operators available. Add an operator first.")
                        .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                        .font(.caption)
                } else {
                    Picker("Select Operator", selection: $formViewModel.selectedOperator) {
                        Text("Choose operator...").tag(nil as Operator?)
                        ForEach(operators) { op in
                            Text(op.name).tag(op as Operator?)
                        }
                    }
                    .onChange(of: formViewModel.selectedOperator) { _, newOperator in
                        formViewModel.handleOperatorChange(newOperator)
                    }
                    
                    if let op = formViewModel.selectedOperator {
                        LabeledContent("Operator ID", value: op.id)
                            .font(.caption)
                            .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                    }
                }
            }
            .listRowBackground(Color.glassBackground)
            
            // Zone Section
            if formViewModel.selectedOperator != nil {
                Section(header: FormSectionHeader(title: "Zone")) {
                    Toggle("Use External Zone ID", isOn: $formViewModel.useExternalZoneId)
                        .onChange(of: formViewModel.useExternalZoneId) { _, isOn in
                            formViewModel.handleExternalZoneToggle(isOn)
                        }
                    
                    if formViewModel.useExternalZoneId {
                        TextField("External Zone ID", text: $formViewModel.externalZoneId, prompt: Text("Zone identifier"))
                            .autocapitalization(.none)
                    } else {
                        if formViewModel.isLoadingZones {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Loading zones...")
                                    .font(.caption)
                                    .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                            }
                        } else if formViewModel.availableZones.isEmpty {
                            Text("No zones available for this operator")
                                .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                                .font(.caption)
                        } else {
                            Picker("Select Zone", selection: $formViewModel.selectedZone) {
                                Text("Choose zone...").tag(nil as Zone?)
                                ForEach(formViewModel.sortedZones) { zone in
                                    Text("\(zone.name) (\(zone.number))").tag(zone as Zone?)
                                }
                            }
                            
                            if let zone = formViewModel.selectedZone {
                                LabeledContent("Zone ID", value: zone.id)
                                    .font(.caption)
                                    .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                            }
                        }
                    }
                }
                .listRowBackground(Color.glassBackground)
            }
            
            // Vehicle Section
            VehicleInputFields(
                vehiclePlate: $formViewModel.vehiclePlate,
                vehicleState: $formViewModel.vehicleState,
                vehicleCountry: $formViewModel.vehicleCountry,
                spaceNumber: $formViewModel.spaceNumber,
                onRandomGenerate: { formViewModel.generateRandomVehicle() }
            )
            
            // Session Times Section
            DatePickerWithQuickActions(
                startTime: $formViewModel.startTime,
                endTime: $formViewModel.endTime,
                onQuickDuration: { formViewModel.setQuickDuration($0) }
            )
            
            // Event Fees Section
            FeesInputFields(
                parkingFee: $formViewModel.parkingFee,
                convenienceFee: $formViewModel.convenienceFee,
                tax: $formViewModel.tax,
                currencyCode: $formViewModel.currencyCode,
                showRandomButton: true,
                onRandomGenerate: { formViewModel.generateRandomFees() }
            )
            
            // Optional Fields Section
            Section(header: FormSectionHeader(title: "Optional")) {
                TextField("Account ID", text: $formViewModel.accountId, prompt: Text("User account UUID"))
                    .autocapitalization(.none)
                
                TextField("Rate Name", text: $formViewModel.rateName, prompt: Text("e.g., $1.25/hour"))
            }
            .listRowBackground(Color.glassBackground)
        }
        .scrollContentBackground(.hidden)
    }
}

#Preview {
    let container = try! ModelContainer(
        for: ParkingSession.self, Operator.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let apiServiceManager = PreviewEnvironment.makePreviewAPIServiceManager()
    let listVM = ParkingSessionsListViewModel(modelContext: container.mainContext)
    let publisher = ParkingSessionEventPublisherViewModel(apiServiceManager: apiServiceManager, listViewModel: listVM)
    let formVM = ParkingSessionEventFormViewModel(apiServiceManager: apiServiceManager, eventPublisher: publisher)
    
    NavigationStack {
        StartSessionFormView(formViewModel: formVM)
            .navigationTitle("Start New Session")
            .adaptiveGlassmorphismBackground()
    }
    .modelContainer(container)
}

