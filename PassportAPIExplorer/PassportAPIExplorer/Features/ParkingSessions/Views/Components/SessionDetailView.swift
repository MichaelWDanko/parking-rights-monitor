//
//  SessionDetailView.swift
//  Passport API Explorer
//
//  Created by Michael Danko on 10/30/25.
//

import SwiftUI

/// Detail view displaying comprehensive information about a parking session.
struct SessionDetailView: View {
    let session: ParkingSession
    let operators: [Operator]
    let onDismiss: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    private var operatorName: String? {
        operators.first(where: { $0.id == session.operatorId })?.name
    }
    
    private var zoneName: String {
        if let zoneName = session.zoneName {
            return zoneName
        }
        if session.computedZoneIdType == .external {
            return "External Zone: \(session.zoneId)"
        }
        return "Unknown Zone"
    }
    
    var body: some View {
        Form {
            Section(header: FormSectionHeader(title: "Vehicle Information")) {
                LabeledContent("License Plate", value: session.vehiclePlate)
                    .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                LabeledContent("State", value: session.vehicleState)
                    .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                LabeledContent("Country", value: session.vehicleCountry)
                    .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                if let spaceNumber = session.spaceNumber {
                    LabeledContent("Space Number", value: spaceNumber)
                        .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                }
            }
            .listRowBackground(Color.glassBackground)
            
            Section(header: FormSectionHeader(title: "Location")) {
                if let operatorName = operatorName {
                    LabeledContent("Operator", value: operatorName)
                        .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                }
                
                HStack {
                    Text("Zone ID Type")
                        .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
                    Spacer()
                    Text(session.computedZoneIdType == .passport ? "Passport" : "External")
                        .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                }
                
                LabeledContent("Zone", value: zoneName)
                    .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
            }
            .listRowBackground(Color.glassBackground)
            
            Section(header: FormSectionHeader(title: "Session Times")) {
                LabeledContent("Start Time", value: session.startTime, format: .dateTime)
                    .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                LabeledContent("End Time", value: session.endTime, format: .dateTime)
                    .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                LabeledContent("Created", value: session.dateCreated, format: .dateTime)
                    .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
            }
            .listRowBackground(Color.glassBackground)
            
            Section(header: FormSectionHeader(title: "API Identifiers")) {
                CopyableIDRow(label: "Session ID", value: session.sessionId)
                CopyableIDRow(label: "Operator ID", value: session.operatorId)
                CopyableIDRow(label: "Zone ID", value: session.zoneId)
            }
            .listRowBackground(Color.glassBackground)
            
            Section(header: FormSectionHeader(title: "Status")) {
                HStack {
                    Text("Session Status")
                        .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
                    Spacer()
                    Text(session.isActive ? "Active" : "Stopped")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(session.isActive ? .green : .red)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(session.isActive ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                        .cornerRadius(6)
                }
            }
            .listRowBackground(Color.glassBackground)
        }
        .scrollContentBackground(.hidden)
        .adaptiveGlassmorphismBackground()
        .navigationTitle("Session Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done", action: onDismiss)
                    .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
            }
        }
    }
}

/// Helper view for displaying copyable ID values.
private struct CopyableIDRow: View {
    let label: String
    let value: String
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.caption)
                .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
            HStack {
                Text(value)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(Color.adaptiveCyanAccent(colorScheme == .dark))
                Spacer()
                Button(action: {
                    UIPasteboard.general.string = value
                }) {
                    Image(systemName: "doc.on.doc")
                        .foregroundColor(Color.adaptiveCyanAccent(colorScheme == .dark))
                }
                .buttonStyle(.borderless)
            }
        }
    }
}

#Preview {
    let mockSession = ParkingSession(
        operatorId: "test-op-id",
        zoneId: "test-zone-id",
        vehiclePlate: "ABC1234",
        vehicleState: "CA",
        endTime: Date().addingTimeInterval(3600)
    )
    
    NavigationStack {
        SessionDetailView(
            session: mockSession,
            operators: [],
            onDismiss: {}
        )
    }
    .adaptiveGlassmorphismBackground()
}

